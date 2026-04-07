import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ship_rate/l10n/app_localizations.dart';
import '../home/home_page.dart';
import '../../main.dart';

/// Registration screen with OTP verification and password creation.
///
/// Three steps:
/// 1. Email input — checks authorized_emails and sends OTP
/// 2. OTP verification — verifies 6-digit code
/// 3. Password creation — sets password for future email+password login
enum _RegisterStep { email, otp, password }

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const _resendCooldown = 60;

  // ===========================================================================
  // CONTROLLERS & STATE
  // ===========================================================================

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  _RegisterStep _step = _RegisterStep.email;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _email = '';
  String _customToken = '';
  int _resendSeconds = 0;
  Timer? _resendTimer;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final n in _otpFocusNodes) {
      n.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  // ===========================================================================
  // METHODS
  // ===========================================================================

  /// Step 1: Send OTP to entered email.
  Future<void> _sendOtp() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim().toLowerCase();

    if (email.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('sendOTP');
      final result = await callable.call({'email': email});

      final data = result.data as Map<String, dynamic>;

      if (data['error'] == 'already-registered') {
        setState(() => _isLoading = false);
        _showSnackBar(l10n.emailAlreadyRegistered,
            color: const Color(0xFFDC2626));
        return;
      }

      setState(() {
        _email = email;
        _step = _RegisterStep.otp;
        _isLoading = false;
      });

      _startResendTimer();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _otpFocusNodes[0].requestFocus();
      });
    } on FirebaseFunctionsException catch (e) {
      setState(() => _isLoading = false);
      if (e.code == 'permission-denied') {
        _showSnackBar(l10n.emailNotAuthorized, color: const Color(0xFFDC2626));
      } else {
        _showSnackBar(e.message ?? 'Error', color: const Color(0xFFDC2626));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(e.toString(), color: const Color(0xFFDC2626));
    }
  }

  /// Step 2: Verify OTP code.
  Future<void> _verifyOtp() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _otpControllers.map((c) => c.text).join();

    if (code.length != 6) return;

    setState(() => _isLoading = true);

    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('verifyOTP');
      final result = await callable.call({'email': _email, 'code': code});

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final token = data['token'] as String;
        setState(() {
          _customToken = token;
          _step = _RegisterStep.password;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        final error = data['error'] as String?;
        if (error == 'expired') {
          _showSnackBar(l10n.expiredCode, color: const Color(0xFFDC2626));
        } else {
          _showSnackBar(l10n.invalidCode, color: const Color(0xFFDC2626));
        }
        _clearOtpFields();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(e.toString(), color: const Color(0xFFDC2626));
    }
  }

  /// Step 3: Create password and complete registration.
  Future<void> _createPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.length < 6) {
      _showSnackBar(l10n.passwordTooShort, color: const Color(0xFFDC2626));
      return;
    }
    if (password != confirm) {
      _showSnackBar(l10n.passwordsDoNotMatch, color: const Color(0xFFDC2626));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Sign in with custom token from OTP verification
      await FirebaseAuth.instance.signInWithCustomToken(_customToken);

      // Link email+password credential so the pilot can log in with password
      final credential = EmailAuthProvider.credential(
        email: _email,
        password: password,
      );
      await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);

      // Navigate immediately to HomePage, clearing the stack
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        if (e.code == 'provider-already-linked' ||
            e.code == 'credential-already-in-use' ||
            e.code == 'email-already-in-use') {
          setState(() => _isLoading = false);
          _showSnackBar(l10n.emailAlreadyRegistered,
              color: const Color(0xFFDC2626));
        } else {
          setState(() => _isLoading = false);
          _showSnackBar(e.message ?? 'Error', color: const Color(0xFFDC2626));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(e.toString(), color: const Color(0xFFDC2626));
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0) return;

    setState(() => _isLoading = true);

    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('sendOTP');
      await callable.call({'email': _email});

      setState(() => _isLoading = false);
      _startResendTimer();
      _clearOtpFields();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(e.toString(), color: const Color(0xFFDC2626));
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = _resendCooldown);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) timer.cancel();
      });
    });
  }

  void _clearOtpFields() {
    for (final c in _otpControllers) {
      c.clear();
    }
    if (mounted) _otpFocusNodes[0].requestFocus();
  }

  void _backToEmail() {
    _resendTimer?.cancel();
    _clearOtpFields();
    setState(() {
      _step = _RegisterStep.email;
      _resendSeconds = 0;
    });
  }

  void _toggleLocale() {
    final next = localeController.locale.languageCode == 'pt'
        ? const Locale('en')
        : const Locale('pt');
    localeController.changeLocale(next);
  }

  void _showSnackBar(String message, {required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0a1628), Color(0xFF0d2137)],
          ),
        ),
        child: Stack(
          children: [
            _buildContent(),
            _buildLocaleToggle(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              if (_step == _RegisterStep.email)
                _buildEmailSection()
              else if (_step == _RegisterStep.otp)
                _buildOtpSection()
              else
                _buildPasswordSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    String subtitle;
    switch (_step) {
      case _RegisterStep.email:
        subtitle = l10n.registerSubtitle;
      case _RegisterStep.otp:
        subtitle = l10n.enterCode;
      case _RegisterStep.password:
        subtitle = l10n.createPassword;
    }

    return Column(
      children: [
        const Icon(
          Icons.directions_boat_filled,
          size: 64,
          color: Color(0xFF64b5f6),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.register,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFFD9D9D9),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1: EMAIL INPUT
  // ---------------------------------------------------------------------------

  Widget _buildEmailSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: l10n.email,
            hintStyle: const TextStyle(color: Color(0x99FFFFFF)),
            prefixIcon:
                const Icon(Icons.email_outlined, color: Color(0x99FFFFFF)),
            filled: true,
            fillColor: const Color(0xFF1A2E45),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x1F64B5F6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x1F64B5F6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF64b5f6), width: 1.5),
            ),
          ),
          onSubmitted: (_) => _isLoading ? null : _sendOtp(),
        ),
        const SizedBox(height: 24),
        _buildGradientButton(
          label: l10n.sendCode,
          onPressed: _isLoading ? null : _sendOtp,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.alreadyHaveAccount,
              style: const TextStyle(
                color: Color(0xFF64b5f6),
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: OTP VERIFICATION
  // ---------------------------------------------------------------------------

  Widget _buildOtpSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _backToEmail,
            icon: const Icon(Icons.arrow_back,
                color: Color(0xFF64b5f6), size: 18),
            label: Text(
              l10n.back,
              style: const TextStyle(color: Color(0xFF64b5f6)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.codeSentTo(_email),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xD9FFFFFF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.enterCode,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0x66FFFFFF),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) => _buildOtpBox(i)),
        ),
        const SizedBox(height: 28),
        _buildGradientButton(
          label: l10n.verify,
          onPressed: _isLoading ? null : _verifyOtp,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _resendSeconds > 0 || _isLoading ? null : _resendOtp,
            child: Text(
              _resendSeconds > 0
                  ? l10n.resendIn(_resendSeconds.toString())
                  : l10n.resendCode,
              style: TextStyle(
                color: _resendSeconds > 0
                    ? const Color(0x66FFFFFF)
                    : const Color(0xFF64b5f6),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 46,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFF1A2E45),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0x1F64B5F6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0x1F64B5F6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFF26a69a), width: 1.5),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          }
          if (index == 5 && value.isNotEmpty) {
            final code = _otpControllers.map((c) => c.text).join();
            if (code.length == 6 && !_isLoading) {
              _verifyOtp();
            }
          }
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: PASSWORD CREATION
  // ---------------------------------------------------------------------------

  Widget _buildPasswordSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Password field
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: l10n.password,
            hintStyle: const TextStyle(color: Color(0x99FFFFFF)),
            prefixIcon:
                const Icon(Icons.lock_outline, color: Color(0x99FFFFFF)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0x99FFFFFF),
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: const Color(0xFF1A2E45),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x1F64B5F6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x1F64B5F6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF64b5f6), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            l10n.passwordHint,
            style: const TextStyle(
              color: Color(0x66FFFFFF),
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Confirm password field
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: l10n.confirmPassword,
            hintStyle: const TextStyle(color: Color(0x99FFFFFF)),
            prefixIcon:
                const Icon(Icons.lock_outline, color: Color(0x99FFFFFF)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0x99FFFFFF),
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            filled: true,
            fillColor: const Color(0xFF1A2E45),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x1F64B5F6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x1F64B5F6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF64b5f6), width: 1.5),
            ),
          ),
          onSubmitted: (_) => _isLoading ? null : _createPassword(),
        ),
        const SizedBox(height: 24),

        // Create password button
        _buildGradientButton(
          label: l10n.createPassword,
          onPressed: _isLoading ? null : _createPassword,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildGradientButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: onPressed != null
            ? const LinearGradient(
                colors: [Color(0xFF1565c0), Color(0xFF1976d2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: onPressed == null ? const Color(0xFF1A2E45) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocaleToggle() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      right: 12,
      child: Material(
        color: Colors.black.withAlpha(60),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: _toggleLocale,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, color: Colors.white70, size: 18),
                const SizedBox(width: 4),
                Text(
                  localeController.locale.languageCode == 'pt' ? 'EN' : 'PT',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

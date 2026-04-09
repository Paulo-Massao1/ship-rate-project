import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';
import '../../main.dart';
import 'register_page.dart';

/// Login screen with email + password authentication.
///
/// Existing pilots sign in with email and password.
/// New pilots tap "Register" to go through OTP registration flow.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ===========================================================================
  // CONTROLLERS & STATE
  // ===========================================================================

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // METHODS
  // ===========================================================================

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  bool _isValidEmail(String email) => _emailRegex.hasMatch(email);

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;

    if (!_isValidEmail(email)) {
      _showSnackBar(l10n.invalidEmail, color: const Color(0xFFDC2626));
      return;
    }
    if (password.length < 6) {
      _showSnackBar(l10n.passwordTooShort, color: const Color(0xFFDC2626));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // AuthGate handles navigation
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        _showSnackBar(l10n.invalidCredentials, color: const Color(0xFFDC2626));
      } else {
        _showSnackBar(e.message ?? 'Error', color: const Color(0xFFDC2626));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(e.toString(), color: const Color(0xFFDC2626));
    }
  }

  void _goToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      _showSnackBar(l10n.enterEmail, color: const Color(0xFFDC2626));
      return;
    }
    if (!_isValidEmail(email)) {
      _showSnackBar(l10n.invalidEmail, color: const Color(0xFFDC2626));
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        _showSnackBar(l10n.resetEmailSent, color: const Color(0xFF26a69a));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString(), color: const Color(0xFFDC2626));
      }
    }
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
    final l10n = AppLocalizations.of(context)!;
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
              _buildLoginForm(),
              const SizedBox(height: 16),
              // Forgot password
              Center(
                child: TextButton(
                  onPressed: _resetPassword,
                  child: Text(
                    l10n.forgotPassword,
                    style: const TextStyle(
                      color: Color(0xFF64b5f6),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Register link
              Center(
                child: TextButton(
                  onPressed: _goToRegister,
                  child: Text(
                    l10n.noAccount,
                    style: const TextStyle(
                      color: Color(0xFF64b5f6),
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const Icon(
          Icons.directions_boat_filled,
          size: 64,
          color: Color(0xFF64b5f6),
        ),
        const SizedBox(height: 16),
        const Text(
          'ShipRate',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.loginSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFFD9D9D9),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email field
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
          onSubmitted: (_) => _isLoading ? null : _login(),
        ),
        const SizedBox(height: 16),

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
          onSubmitted: (_) => _isLoading ? null : _login(),
        ),
        const SizedBox(height: 24),

        // Login button
        _buildGradientButton(
          label: l10n.loginButton,
          onPressed: _isLoading ? null : _login,
        ),
      ],
    );
  }

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

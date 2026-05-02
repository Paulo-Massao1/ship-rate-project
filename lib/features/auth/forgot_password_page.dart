import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';
import '../../controllers/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Password recovery screen.
///
/// Allows users to request a password reset email via Firebase Authentication.
/// On success, returns to login screen.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // ===========================================================================
  // CONTROLLERS & STATE
  // ===========================================================================

  final _emailController = TextEditingController();
  final _authController = AuthController();

  bool _isLoading = false;
  bool _emailSent = false;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  bool _isValidEmail(String email) => _emailRegex.hasMatch(email);

  /// Sends password reset email.
  Future<void> _sendResetEmail() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim().toLowerCase();

    if (email.isEmpty) return;

    if (!_isValidEmail(email)) {
      _showSnackBar(l10n.invalidEmail, color: AppColors.danger);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authController.sendPasswordReset(_emailController.text.trim());

      if (!mounted) return;

      setState(() => _emailSent = true);
    } catch (error) {
      _showSnackBar(error.toString(), color: AppColors.danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Shows a floating snackbar.
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
      body: Stack(
        children: [
          _buildBackgroundImage(),
          _buildOverlay(),
          _buildResetCard(),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return Image.asset(
      'assets/images/navio.jpg',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  Widget _buildOverlay() {
    return Container(color: Colors.black.withAlpha(115));
  }

  Widget _buildResetCard() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _emailSent
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 48,
                          color: Color(0xFF4CAF50),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.resetEmailSent,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSpamNotice(),
                        const SizedBox(height: 24),
                        _buildBackToLoginLink(),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildEmailField(),
                        const SizedBox(height: 24),
                        _buildSendButton(),
                        const SizedBox(height: 12),
                        _buildSpamNotice(),
                        const SizedBox(height: 16),
                        _buildBackToLoginLink(),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const Icon(Icons.lock_reset, size: 48, color: AppColors.primary),
        const SizedBox(height: 16),
        Text(
          l10n.recoverPassword,
          textAlign: TextAlign.center,
          style: AppTextStyles.title,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.recoverPasswordSubtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.subtitle,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(labelText: l10n.email),
    );
  }

  Widget _buildSendButton() {
    final l10n = AppLocalizations.of(context)!;
    return ElevatedButton(
      onPressed: _isLoading ? null : _sendResetEmail,
      child: _isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(l10n.sendLink),
    );
  }

  Widget _buildSpamNotice() {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      l10n.spamNotice,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.black54, fontSize: 13),
    );
  }

  Widget _buildBackToLoginLink() {
    final l10n = AppLocalizations.of(context)!;
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(l10n.backToLogin),
    );
  }
}

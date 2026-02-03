import 'package:flutter/material.dart';
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

  /// Sends password reset email.
  ///
  /// Flow:
  /// 1. Activates loading state
  /// 2. Calls [AuthController.sendPasswordReset]
  /// 3. Shows success feedback
  /// 4. Navigates back to login screen
  /// 5. On error, shows error message
  Future<void> _sendResetEmail() async {
    setState(() => _isLoading = true);

    try {
      await _authController.sendPasswordReset(_emailController.text.trim());

      if (!mounted) return;

      _showSnackBar(
        'Enviamos um link de recuperação para o seu e-mail.',
        color: AppColors.success,
      );

      Navigator.pop(context);
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
              child: Column(
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
    return const Column(
      children: [
        Icon(Icons.lock_reset, size: 48, color: AppColors.primary),
        SizedBox(height: 16),
        Text(
          'Recuperar senha',
          textAlign: TextAlign.center,
          style: AppTextStyles.title,
        ),
        SizedBox(height: 8),
        Text(
          'Informe seu e-mail para receber o link de redefinição',
          textAlign: TextAlign.center,
          style: AppTextStyles.subtitle,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(labelText: 'E-mail'),
    );
  }

  Widget _buildSendButton() {
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
          : const Text('Enviar link'),
    );
  }

  Widget _buildSpamNotice() {
    return const Text(
      'Caso não encontre o e-mail, verifique também sua caixa de SPAM ou Lixo Eletrônico.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.black54, fontSize: 13),
    );
  }

  Widget _buildBackToLoginLink() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Voltar para o login'),
    );
  }
}
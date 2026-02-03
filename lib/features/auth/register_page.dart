// lib/features/auth/register_page.dart

import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Registration screen for new ShipRate users.
///
/// Collects:
/// - Call sign (public identifier for the pilot)
/// - Email
/// - Password and confirmation
///
/// On success, navigates back to login screen.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ===========================================================================
  // CONTROLLERS & STATE
  // ===========================================================================

  final _callSignController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authController = AuthController();

  bool _isLoading = false;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void dispose() {
    _callSignController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  /// Registers a new user.
  ///
  /// Flow:
  /// 1. Activates loading state
  /// 2. Calls [AuthController.register]
  /// 3. Shows success feedback
  /// 4. Navigates back to login screen
  /// 5. On error, shows error message
  Future<void> _register() async {
    setState(() => _isLoading = true);

    try {
      await _authController.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        confirmPassword: _confirmPasswordController.text.trim(),
        callSign: _callSignController.text.trim(),
      );

      if (!mounted) return;

      _showSnackBar('Cadastro realizado com sucesso', color: AppColors.success);
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
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildBackgroundImage(),
          _buildOverlay(),
          _buildRegisterCard(),
        ],
      ),
    );
  }

  /// Background image for branding.
  Widget _buildBackgroundImage() {
    return Image.asset(
      'assets/images/navio.jpg',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  /// Dark overlay for better contrast.
  Widget _buildOverlay() {
    return Container(color: Colors.black.withAlpha(130));
  }

  /// Centered registration card with form.
  Widget _buildRegisterCard() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 10,
            shadowColor: Colors.black26,
            surfaceTintColor: AppColors.primary.withAlpha(40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildCallSignField(),
                  const SizedBox(height: 16),
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                  const SizedBox(height: 16),
                  _buildConfirmPasswordField(),
                  const SizedBox(height: 28),
                  _buildRegisterButton(),
                  const SizedBox(height: 16),
                  _buildLoginLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Header with icon and title.
  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(Icons.person_add_alt_1, size: 54, color: AppColors.primary),
        const SizedBox(height: 16),
        Text(
          'Criar conta',
          textAlign: TextAlign.center,
          style: AppTextStyles.title.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 6),
        const Text(
          'Preencha os dados para continuar',
          textAlign: TextAlign.center,
          style: AppTextStyles.subtitle,
        ),
      ],
    );
  }

  /// Call sign input field (public identifier).
  Widget _buildCallSignField() {
    return TextField(
      controller: _callSignController,
      decoration: InputDecoration(
        labelText: 'Nome de guerra',
        prefixIcon: const Icon(Icons.account_circle),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Email input field.
  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'E-mail',
        prefixIcon: const Icon(Icons.email),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Password input field.
  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Senha',
        prefixIcon: const Icon(Icons.lock),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Confirm password input field.
  Widget _buildConfirmPasswordField() {
    return TextField(
      controller: _confirmPasswordController,
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Confirmar senha',
        prefixIcon: const Icon(Icons.lock_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Register button with loading indicator.
  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _register,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text('Cadastrar', style: TextStyle(fontSize: 18)),
    );
  }

  /// Link to return to login screen.
  Widget _buildLoginLink() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text(
        'Já tenho uma conta',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
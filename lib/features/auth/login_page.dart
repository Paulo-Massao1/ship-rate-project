import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../home/main_screen_page.dart';

/// Login screen for ShipRate app.
///
/// Responsibilities:
/// - Collect user credentials (email and password)
/// - Trigger authentication via [AuthController]
/// - Display feedback via SnackBar
/// - Navigate to [MainScreen] on success
/// - Provide access to password recovery and registration
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
  final _authController = AuthController();

  bool _isLoading = false;

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
  // ACTIONS
  // ===========================================================================

  /// Performs user login.
  ///
  /// Flow:
  /// 1. Activates loading state
  /// 2. Calls [AuthController.login]
  /// 3. Shows success feedback
  /// 4. Navigates to MainScreen using pushReplacement
  /// 5. On error, shows error message
  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      await _authController.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      _showSnackBar('Login realizado com sucesso', color: AppColors.success);

      if (!mounted) return;

      // Replace login screen to prevent back navigation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (error) {
      _showSnackBar(error.toString(), color: AppColors.danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Navigates to forgot password screen.
  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
    );
  }

  /// Navigates to registration screen.
  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  /// Shows a floating snackbar with message.
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
          _buildLoginCard(),
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

  /// Centered login card with form.
  Widget _buildLoginCard() {
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
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                  const SizedBox(height: 28),
                  _buildLoginButton(),
                  const SizedBox(height: 16),
                  _buildForgotPasswordLink(),
                  const Divider(height: 32),
                  _buildRegisterLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Header with logo and title.
  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(
          Icons.directions_boat_filled,
          size: 54,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'ShipRate',
          textAlign: TextAlign.center,
          style: AppTextStyles.title.copyWith(fontSize: 30),
        ),
        const SizedBox(height: 6),
        const Text(
          'Entre com seu e-mail e senha para continuar',
          textAlign: TextAlign.center,
          style: AppTextStyles.subtitle,
        ),
      ],
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

  /// Login button with loading indicator.
  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text('Entrar', style: TextStyle(fontSize: 18)),
    );
  }

  /// Forgot password link.
  Widget _buildForgotPasswordLink() {
    return TextButton(
      onPressed: _navigateToForgotPassword,
      child: const Text('Esqueci minha senha'),
    );
  }

  /// Register link.
  Widget _buildRegisterLink() {
    return TextButton(
      onPressed: _navigateToRegister,
      child: const Text(
        'Criar nova conta',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }
}
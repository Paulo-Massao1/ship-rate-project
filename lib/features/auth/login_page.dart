import 'package:flutter/material.dart';
import 'auth_controller.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../home/main_screen_page.dart';

/// Tela de Login do ShipRate.
///
/// Responsabilidades:
/// ------------------
/// • Coletar credenciais (e-mail e senha) do usuário
/// • Disparar o fluxo de autenticação via [AuthController.login]
/// • Exibir mensagens de sucesso/erro via SnackBar
/// • Redirecionar para a [MainScreen] após login bem-sucedido
/// • Encaminhar para:
///     - tela de recuperação de senha
///     - tela de cadastro (novo usuário)
///
/// Observações:
/// ------------
/// • A navegação para a home é feita via `Navigator.pushReplacement`
///   para que o usuário não consiga voltar para o login ao usar o botão “voltar”.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /// Controller do campo de e-mail.
  final _emailController = TextEditingController();

  /// Controller do campo de senha.
  final _senhaController = TextEditingController();

  /// Camada de controle responsável por autenticação (Firebase Auth + Firestore).
  final _authController = AuthController();

  /// Flag de carregamento para desabilitar o botão de login
  /// enquanto a requisição está em andamento.
  bool isLoading = false;

  /// Realiza o login do usuário com base nos dados dos campos.
  ///
  /// Fluxo:
  ///   1) Ativa loading
  ///   2) Chama [_authController.login]
  ///   3) Exibe snackbar de sucesso
  ///   4) Redireciona para [MainScreen] com `pushReplacement`
  ///   5) Em caso de erro, exibe mensagem amigável (AuthException.toString())
  Future<void> _login() async {
    setState(() => isLoading = true);

    try {
      await _authController.login(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      // Se chegou até aqui, login foi bem-sucedido.
      _showSnackBar(
        'Login realizado com sucesso',
        color: AppColors.success,
      );

      if (!mounted) return;

      // Substitui a tela de login pela MainScreen,
      // evitando que o usuário retorne para o login ao pressionar "Voltar".
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (e) {
      _showSnackBar(
        e.toString(),
        color: AppColors.danger,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// Exibe uma mensagem de feedback (sucesso/erro) na forma de SnackBar.
  void _showSnackBar(String message, {required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          /// Imagem de fundo ocupando a tela inteira.
          Image.asset(
            'assets/images/navio.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          /// Overlay escuro para dar contraste aos elementos em primeiro plano.
          Container(color: Colors.black.withAlpha(130)),

          /// Card central com formulário de login.
          Center(
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
                        const Icon(
                          Icons.directions_boat_filled,
                          size: 54,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),

                        /// Título principal do app.
                        Text(
                          'ShipRate',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.title.copyWith(fontSize: 30),
                        ),
                        const SizedBox(height: 6),

                        /// Subtítulo explicando a ação esperada.
                        const Text(
                          'Entre com seu e-mail e senha para continuar',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: 32),

                        /// Campo de e-mail.
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// Campo de senha.
                        TextField(
                          controller: _senhaController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        /// Botão principal de login.
                        ElevatedButton(
                          onPressed: isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Entrar',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),

                        const SizedBox(height: 16),

                        /// Atalho para fluxo de recuperação de senha.
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: const Text('Esqueci minha senha'),
                        ),

                        const Divider(height: 32),

                        /// Atalho para cadastro de nova conta.
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Criar nova conta',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

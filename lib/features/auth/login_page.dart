import 'package:flutter/material.dart';
import 'auth_controller.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../home/main_screen_page.dart';

/// ============================================================================
/// LOGIN PAGE
/// ============================================================================
/// Tela de login do ShipRate.
///
/// Responsabilidades:
/// ------------------
/// • Coletar credenciais (e-mail e senha) do usuário
/// • Disparar fluxo de autenticação via [AuthController.login]
/// • Exibir feedback visual de sucesso/erro via SnackBar
/// • Redirecionar para [MainScreen] após login bem-sucedido
/// • Fornecer acesso às telas de:
///     - Recuperação de senha [ForgotPasswordPage]
///     - Cadastro de novo usuário [RegisterPage]
///
/// Fluxo de Navegação:
/// -------------------
/// • Usa `Navigator.pushReplacement` após login bem-sucedido para evitar
///   que o usuário retorne à tela de login ao pressionar o botão "Voltar"
///
/// UX/UI:
/// ------
/// • Card centralizado sobre imagem de fundo com overlay escuro
/// • Suporte responsivo (mobile e web) através de constraints
/// • Loading state visual durante autenticação
/// • Feedback claro de erros através de SnackBars coloridas
///
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /// Controller do campo de e-mail
  final _emailController = TextEditingController();

  /// Controller do campo de senha
  final _passwordController = TextEditingController();

  /// Controlador de autenticação (Firebase Auth + Firestore)
  final _authController = AuthController();

  /// Flag para controlar estado de carregamento e desabilitar botão durante operação
  bool _isLoading = false;

  /// --------------------------------------------------------------------------
  /// Realiza login do usuário
  /// --------------------------------------------------------------------------
  /// Fluxo de execução:
  ///   1. Ativa loading (desabilita botão)
  ///   2. Chama [AuthController.login] com credenciais
  ///   3. Exibe feedback de sucesso via SnackBar
  ///   4. Redireciona para [MainScreen] usando pushReplacement
  ///   5. Em caso de erro, exibe mensagem clara ao usuário
  ///
  /// Observações:
  ///   • `pushReplacement` remove tela de login da pilha de navegação
  ///   • Previne usuário de voltar para login após autenticação
  ///   • Erros são capturados como [AuthException] com mensagens amigáveis
  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      await _authController.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      /// Login bem-sucedido - exibe feedback positivo
      _showSnackBar(
        'Login realizado com sucesso',
        color: AppColors.success,
      );

      if (!mounted) return;

      /// Substitui tela de login pela MainScreen
      /// Evita que usuário retorne ao login ao pressionar "Voltar"
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (error) {
      _showSnackBar(
        error.toString(),
        color: AppColors.danger,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// --------------------------------------------------------------------------
  /// Exibe Snackbar padronizada
  /// --------------------------------------------------------------------------
  /// Mostra feedback visual flutuante com mensagem e cor customizável.
  ///
  /// Parâmetros:
  ///   • [message] - Texto a ser exibido
  ///   • [color] - Cor de fundo (sucesso/erro)
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
          /// -------------------------------------------------------------------
          /// Imagem de fundo
          /// -------------------------------------------------------------------
          /// Reforça identidade visual do aplicativo
          Image.asset(
            'assets/images/navio.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          /// -------------------------------------------------------------------
          /// Overlay escuro
          /// -------------------------------------------------------------------
          /// Garante contraste e legibilidade do conteúdo
          Container(color: Colors.black.withAlpha(130)),

          /// -------------------------------------------------------------------
          /// Card de login centralizado
          /// -------------------------------------------------------------------
          /// SingleChildScrollView permite scroll em telas menores
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
                        /// Ícone de identificação visual do app
                        const Icon(
                          Icons.directions_boat_filled,
                          size: 54,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),

                        /// Título principal - nome do aplicativo
                        Text(
                          'ShipRate',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.title.copyWith(fontSize: 30),
                        ),
                        const SizedBox(height: 6),

                        /// Subtítulo com instrução ao usuário
                        const Text(
                          'Entre com seu e-mail e senha para continuar',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: 32),

                        /// Campo de entrada de e-mail
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

                        /// Campo de entrada de senha
                        TextField(
                          controller: _passwordController,
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

                        /// Botão principal de login
                        /// Substituído por CircularProgressIndicator durante processamento
                        ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                              : const Text(
                                  'Entrar',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),

                        const SizedBox(height: 16),

                        /// Link para recuperação de senha
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

                        /// Link para cadastro de nova conta
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
import 'package:flutter/material.dart';
import 'auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// ============================================================================
/// REGISTER PAGE
/// ============================================================================
/// Tela de criação de conta no ShipRate.
///
/// Objetivo Principal:
/// -------------------
/// Permitir que um novo usuário se registre fornecendo:
///   • Nome de guerra (identificação do prático)
///   • E-mail
///   • Senha e confirmação
///
/// Funcionalidades:
/// ----------------
/// 1. Validação de campos executada no [AuthController.register]
/// 2. Após criação bem-sucedida:
///      - Usuário é cadastrado via Firebase Auth
///      - Dados complementares (nomeGuerra e email) são salvos no Firestore
/// 3. Em caso de sucesso:
///      - SnackBar positiva é exibida
///      - Retorna para tela de Login [Navigator.pop]
/// 4. Em caso de erro:
///      - Mensagens amigáveis via [AuthException] são exibidas
///
/// UX/UI:
/// ------
/// • Fundo com imagem + overlay escuro para contraste
/// • Card centralizado com formulário estilizado
/// • Botão com indicador de carregamento (evita múltiplos submits)
/// • Suporte responsivo (mobile e web) através de constraints
///
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  /// Controller do campo de nome de guerra
  final _callSignController = TextEditingController();

  /// Controller do campo de e-mail
  final _emailController = TextEditingController();

  /// Controller do campo de senha
  final _passwordController = TextEditingController();

  /// Controller do campo de confirmação de senha
  final _confirmPasswordController = TextEditingController();

  /// Controlador de autenticação (Firebase Auth + Firestore)
  final _authController = AuthController();

  /// Flag para controlar estado de carregamento e desabilitar botão durante operação
  bool _isLoading = false;

  /// --------------------------------------------------------------------------
  /// Realiza cadastro de novo usuário
  /// --------------------------------------------------------------------------
  /// Fluxo de execução:
  ///   1. Ativa loading (desabilita botão)
  ///   2. Chama [AuthController.register] com dados do formulário
  ///   3. Exibe feedback de sucesso via SnackBar
  ///   4. Retorna para tela anterior (LoginPage)
  ///   5. Em caso de erro, exibe mensagem clara ao usuário
  ///
  /// Observações:
  ///   • Validações são executadas no AuthController
  ///   • Navigator.pop remove tela de registro da pilha
  ///   • Erros são capturados como [AuthException] com mensagens amigáveis
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

      _showSnackBar(
        'Cadastro realizado com sucesso',
        color: AppColors.success,
      );

      /// Retorna para tela de login após cadastro bem-sucedido
      Navigator.pop(context);
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
          /// Card de cadastro centralizado
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
                        /// Ícone de identificação visual
                        const Icon(
                          Icons.person_add_alt_1,
                          size: 54,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),

                        /// Título da página
                        Text(
                          'Criar conta',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.title.copyWith(fontSize: 28),
                        ),

                        const SizedBox(height: 6),

                        /// Subtítulo com instrução ao usuário
                        const Text(
                          'Preencha os dados para continuar',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subtitle,
                        ),

                        const SizedBox(height: 32),

                        /// Campo de entrada de nome de guerra
                        /// Identificador público usado nas avaliações
                        TextField(
                          controller: _callSignController,
                          decoration: InputDecoration(
                            labelText: 'Nome de guerra',
                            prefixIcon: const Icon(Icons.account_circle),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// Campo de entrada de e-mail
                        /// Usado para autenticação no Firebase Auth
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

                        const SizedBox(height: 16),

                        /// Campo de confirmação de senha
                        /// Validado no AuthController
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Confirmar senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        /// Botão principal de cadastro
                        /// Substituído por CircularProgressIndicator durante processamento
                        ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                              : const Text(
                                  'Cadastrar',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),

                        const SizedBox(height: 16),

                        /// Link de retorno para tela de login
                        /// Para usuários que já possuem conta
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Já tenho uma conta',
                            style: TextStyle(fontWeight: FontWeight.w600),
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
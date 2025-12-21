import 'package:flutter/material.dart';
import 'auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Tela de criação de conta no ShipRate.
///
/// Objetivo principal:
/// --------------------
/// Permitir que um novo usuário registre-se fornecendo:
///   • nome de guerra (identificação do prático)
///   • e-mail
///   • senha e confirmação
///
/// Funcionalidades internas:
/// -------------------------
/// 1. Validação básica de campos é executada no controller (`AuthController.register`)
/// 2. Após criação bem-sucedida:
///      - o usuário é cadastrado via Firebase Auth
///      - dados complementares (nomeGuerra e email) são gravados no Firestore
/// 3. Em caso de sucesso:
///      - uma snackbar positiva é exibida
///      - o usuário retorna para a tela de Login (`Navigator.pop`)
///
/// 4. Em caso de erros:
///      - mensagens amigáveis via `AuthException` são mostradas ao usuário.
///
/// UI:
/// ----
/// • Fundo com imagem + overlay escuro para contraste
/// • Card central com formulário estilizado
/// • Botão com indicador de carregamento para evitar múltiplos submits
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  /// Controllers para armazenar os valores digitados nos campos do formulário.
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _nomeGuerraController = TextEditingController();

  /// Controller responsável pela lógica de autenticação/registro.
  final _authController = AuthController();

  /// Flag usada para exibir ProgressIndicator e desabilitar botão.
  bool isLoading = false;

  /// Método acionado ao tocar no botão "Cadastrar".
  ///
  /// Fluxo:
  ///  1) Define loading=true
  ///  2) Chama `register()` do AuthController
  ///  3) Exibe mensagem de sucesso
  ///  4) Retorna à tela anterior (LoginPage)
  ///  5) Em caso de erro, exibe mensagem apropriada
  Future<void> _register() async {
    setState(() => isLoading = true);

    try {
      await _authController.register(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
        confirmPassword: _confirmarSenhaController.text.trim(),
        nomeGuerra: _nomeGuerraController.text.trim(),
      );

      if (!mounted) return;

      _showSnackBar(
        'Cadastro realizado com sucesso',
        color: AppColors.success,
      );

      // Retorna para a tela anterior (LoginPage)
      Navigator.pop(context);

    } catch (e) {
      _showSnackBar(
        e.toString(),
        color: AppColors.danger,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// Método utilitário para exibir SnackBars coloridas.
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
          /// Imagem de fundo cobrindo toda a tela.
          Image.asset(
            'assets/images/navio.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          /// Overlay escuro para melhorar contraste com o formulário.
          Container(color: Colors.black.withAlpha(130)),

          /// Card central contendo o formulário de cadastro.
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
                          Icons.person_add_alt_1,
                          size: 54,
                          color: AppColors.primary,
                        ),
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

                        const SizedBox(height: 32),

                        /// Nome de guerra — identificador do prático.
                        TextField(
                          controller: _nomeGuerraController,
                          decoration: InputDecoration(
                            labelText: 'Nome de guerra',
                            prefixIcon: const Icon(Icons.account_circle),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// E-mail usado para autenticação no Firebase Auth.
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

                        const SizedBox(height: 16),

                        /// Campo de confirmação de senha.
                        TextField(
                          controller: _confirmarSenhaController,
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

                        /// Botão de ação principal do formulário.
                        ElevatedButton(
                          onPressed: isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
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

                        /// Caso o usuário já tenha uma conta, retorna para Login.
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

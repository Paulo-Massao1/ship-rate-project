import 'package:flutter/material.dart';
import 'auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Página responsável pelo fluxo de recuperação de senha.
///
/// Objetivo:
/// ---------
/// Permitir que o usuário informe seu e-mail e receba o link automático
/// de redefinição fornecido pelo Firebase Authentication.
///
/// Características principais:
/// ---------------------------
/// • Autenticação delegada ao método sendPasswordReset do AuthController
/// • Notificação por Snackbar em caso de sucesso ou erro
/// • Indicador de carregamento enquanto a operação está em andamento
/// • UI responsiva com centralização e Card elegante sobre imagem de fundo
///
/// UX:
/// ---
/// O fundo com overlay escuro melhora contraste.
/// O uso de `ConstrainedBox(maxWidth: 420)` garante visual consistente
/// tanto em web quanto mobile.
///
/// Observação importante:
/// -----------------------
/// Um aviso é exibido ao usuário recomendando checar SPAM e lixo eletrônico,
/// pois o e-mail de recuperação pode ser filtrado automaticamente.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  /// Controller responsável por capturar o texto do e-mail informado.
  final _emailController = TextEditingController();

  /// Instância do AuthController encarregada de acionar o Firebase.
  final _authController = AuthController();

  /// Flag utilizada para controlar estado de carregamento
  /// desabilitando o botão durante a operação.
  bool isLoading = false;

  /// Envia o e-mail de redefinição de senha.
  ///
  /// Fluxo:
  ///  1) ativa loading
  ///  2) chama AuthController.sendPasswordReset
  ///  3) exibe snackbar de sucesso
  ///  4) retorna para tela anterior
  ///  5) captura exceções de autenticação e mostra mensagens claras
  Future<void> _sendResetEmail() async {
    setState(() => isLoading = true);

    try {
      await _authController.sendPasswordReset(
        _emailController.text.trim(),
      );

      if (!mounted) return;

      _showSnackBar(
        'Enviamos um link de recuperação para o seu e-mail.',
        color: AppColors.success,
      );

      // Ao enviar com sucesso, volta para tela de login
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

  /// Exibe Snackbars padronizados de sucesso/erro
  /// de modo flutuante sobre a interface.
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
      body: Stack(
        children: [
          /// Imagem de fundo — reforça identidade visual do app.
          Image.asset(
            'assets/images/navio.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          /// Overlay translúcido para garantir leitura confortável.
          Container(color: Colors.black.withAlpha(115)),

          /// Formulário centralizado com scroll para suportar telas menores.
          Center(
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
                        const Icon(
                          Icons.lock_reset,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Recuperar senha',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.title,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Informe seu e-mail para receber o link de redefinição',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subtitle,
                        ),

                        const SizedBox(height: 32),

                        /// Campo de e-mail digitado pelo usuário.
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                          ),
                        ),
                        const SizedBox(height: 24),

                        /// Botão de envio, substituído por loader enquanto processa.
                        ElevatedButton(
                          onPressed: isLoading ? null : _sendResetEmail,
                          child: isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Enviar link'),
                        ),

                        const SizedBox(height: 12),

                        /// Aviso complementar: check no SPAM.
                        const Text(
                          'Caso não encontre o e-mail, verifique também sua caixa de SPAM ou Lixo Eletrônico.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// Retorno seguro para tela anterior (LoginPage)
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Voltar para o login'),
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

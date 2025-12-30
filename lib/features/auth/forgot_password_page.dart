import 'package:flutter/material.dart';
import 'auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// ============================================================================
/// FORGOT PASSWORD PAGE
/// ============================================================================
/// Página responsável pelo fluxo de recuperação de senha.
///
/// Objetivo:
/// ---------
/// Permitir que o usuário informe seu e-mail e receba um link de redefinição
/// de senha através do Firebase Authentication.
///
/// Características Principais:
/// ---------------------------
/// • Autenticação delegada ao [AuthController.sendPasswordReset]
/// • Feedback visual através de Snackbar (sucesso/erro)
/// • Indicador de carregamento durante processamento
/// • UI responsiva com Card centralizado sobre imagem de fundo
/// • Suporte para web e mobile através de constraints
///
/// UX/UI:
/// ------
/// • Fundo com overlay escuro para melhor contraste e legibilidade
/// • Card com elevação e bordas arredondadas (design moderno)
/// • Máxima largura de 420px garante visual consistente em todas as telas
/// • Aviso sobre SPAM para reduzir confusão do usuário
///
/// Fluxo de Uso:
/// -------------
/// 1. Usuário digita e-mail
/// 2. Clica em "Enviar link"
/// 3. Sistema envia e-mail via Firebase
/// 4. Feedback de sucesso/erro é exibido
/// 5. Em caso de sucesso, retorna automaticamente para tela de login
///
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  /// Controller responsável por capturar o e-mail informado pelo usuário
  final _emailController = TextEditingController();

  /// Instância do controlador de autenticação
  final _authController = AuthController();

  /// Flag para controlar estado de carregamento e desabilitar botão durante operação
  bool _isLoading = false;

  /// --------------------------------------------------------------------------
  /// Envia e-mail de recuperação de senha
  /// --------------------------------------------------------------------------
  /// Fluxo de execução:
  ///   1. Ativa loading (desabilita botão)
  ///   2. Chama [AuthController.sendPasswordReset]
  ///   3. Exibe feedback de sucesso via Snackbar
  ///   4. Retorna para tela anterior (LoginPage)
  ///   5. Em caso de erro, exibe mensagem clara ao usuário
  ///
  /// Tratamento de Erro:
  ///   • Captura [AuthException] com mensagens amigáveis
  ///   • Exibe Snackbar vermelho em caso de falha
  ///   • Mantém usuário na tela para nova tentativa
  Future<void> _sendResetEmail() async {
    setState(() => _isLoading = true);

    try {
      await _authController.sendPasswordReset(
        _emailController.text.trim(),
      );

      if (!mounted) return;

      _showSnackBar(
        'Enviamos um link de recuperação para o seu e-mail.',
        color: AppColors.success,
      );

      /// Retorna para tela de login após envio bem-sucedido
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
          Container(color: Colors.black.withAlpha(115)),

          /// -------------------------------------------------------------------
          /// Formulário centralizado
          /// -------------------------------------------------------------------
          /// SingleChildScrollView permite scroll em telas menores
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
                        /// Ícone de identificação visual
                        const Icon(
                          Icons.lock_reset,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),

                        /// Título da página
                        const Text(
                          'Recuperar senha',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.title,
                        ),
                        const SizedBox(height: 8),

                        /// Descrição/instrução
                        const Text(
                          'Informe seu e-mail para receber o link de redefinição',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subtitle,
                        ),

                        const SizedBox(height: 32),

                        /// Campo de entrada de e-mail
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                          ),
                        ),
                        const SizedBox(height: 24),

                        /// Botão de envio com loading
                        /// Substituído por CircularProgressIndicator durante processamento
                        ElevatedButton(
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
                        ),

                        const SizedBox(height: 12),

                        /// Aviso importante sobre SPAM
                        /// Reduz tickets de suporte de "não recebi o e-mail"
                        const Text(
                          'Caso não encontre o e-mail, verifique também sua caixa de SPAM ou Lixo Eletrônico.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// Link de retorno para tela de login
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
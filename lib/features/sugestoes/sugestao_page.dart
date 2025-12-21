import 'package:flutter/material.dart';
import 'package:ship_rate/data/services/sugestao_service.dart';

/// ============================================================================
/// SugestaoPage
/// ============================================================================
/// Tela responsável por permitir que o usuário envie sugestões sobre o app.
///
/// OBJETIVOS PRINCIPAIS:
///  • Captura de e-mail, título e descrição.
///  • Envio via SugestaoService (Firestore).
///  • Feedback ao usuário via SnackBar.
///  • UI simples e direta.
///
/// NOTAS ARQUITETURAIS:
///  • Não faz validação complexa — ideal para ser validada futuramente.
///  • Reaproveita SugestaoService para manter controller/service separado da UI.
///  • Navegação: retorna para tela anterior após sucesso.
///
/// Firestore:
///  • Coleção: "sugestoes"
///  • Campos persistidos: email, titulo, mensagem, createdAt
///
/// ============================================================================

class SugestaoPage extends StatefulWidget {
  const SugestaoPage({super.key});

  @override
  State<SugestaoPage> createState() => _SugestaoPageState();
}

class _SugestaoPageState extends State<SugestaoPage> {
  /// Controllers dos campos de entrada
  final _emailController = TextEditingController();
  final _tituloController = TextEditingController();
  final _mensagemController = TextEditingController();

  /// Estado para exibir carregamento durante envio
  bool isLoading = false;

  /// --------------------------------------------------------------------------
  /// _enviar()
  /// --------------------------------------------------------------------------
  /// Ação disparada ao clicar no botão "Enviar".
  ///
  /// Regras:
  ///  • dispara SugestaoService.enviar(...)
  ///  • exibe SnackBar com sucesso ou falha
  ///  • desabilita botão enquanto envia
  ///  • retorna à tela anterior em caso de sucesso
  ///
  /// Não possui validação obrigatória — intencional para simplicidade inicial.
  /// Pode ser estendida com validações de campo no futuro.
  /// --------------------------------------------------------------------------
  Future<void> _enviar() async {
    setState(() => isLoading = true);

    final ok = await SugestaoService.enviar(
      email: _emailController.text.trim(),
      titulo: _tituloController.text.trim(),
      mensagem: _mensagemController.text.trim(),
    );

    setState(() => isLoading = false);

    if (!mounted) return;

    /// Feedback ao usuário via SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? "Sugestão enviada com sucesso!" : "Erro ao enviar sugestão.",
        ),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );

    /// Retorna à tela anterior apenas se sucesso
    if (ok) Navigator.pop(context);
  }

  /// --------------------------------------------------------------------------
  /// build()
  /// --------------------------------------------------------------------------
  /// Renderiza a interface:
  ///  • AppBar
  ///  • Formulário simples
  ///  • Button com loader
  ///
  /// UI focada em simplicidade e clareza.
  /// --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enviar Sugestão")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Campo de e-mail
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Seu e-mail"),
            ),

            /// Campo título
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(labelText: "Título"),
            ),

            /// Campo mensagem
            TextField(
              controller: _mensagemController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Mensagem"),
            ),

            const SizedBox(height: 20),

            /// Botão enviar (ou indicador de loading)
            ElevatedButton(
              onPressed: isLoading ? null : _enviar,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Enviar"),
            )
          ],
        ),
      ),
    );
  }
}

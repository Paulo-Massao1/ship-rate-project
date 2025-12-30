import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ship_rate/data/services/suggestion_service.dart';

/// ============================================================================
/// SUGGESTION PAGE
/// ============================================================================
/// Tela responsável por permitir que o usuário envie sugestões
/// e feedbacks para melhoria do aplicativo ShipRate.
///
/// A sugestão é enviada utilizando o [SuggestionService].
class SuggestionPage extends StatefulWidget {
  const SuggestionPage({super.key});

  @override
  State<SuggestionPage> createState() => _SuggestionPageState();
}

class _SuggestionPageState extends State<SuggestionPage> {
  /// Controller do campo de mensagem
  final TextEditingController _messageController = TextEditingController();

  /// Tipo de contato selecionado
  String _contactType = 'Sugestão';

  /// Controle de loading do botão
  bool _isLoading = false;

  /// --------------------------------------------------------------------------
  /// Envia a sugestão utilizando o service
  /// --------------------------------------------------------------------------
  Future<void> _submitSuggestion() async {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, escreva sua mensagem.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await SuggestionService.send(
      email: email,
      title: _contactType,
      message: _messageController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Mensagem enviada com sucesso!'
              : 'Erro ao enviar mensagem.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Enviar Sugestão',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sua opinião é importante',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Ajude a melhorar o ShipRate com sugestões e ideias.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),

            /// Dropdown de tipo de contato
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _contactType,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  items: const [
                    DropdownMenuItem(
                      value: 'Sugestão',
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline, size: 20),
                          SizedBox(width: 12),
                          Text('Sugestão'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Crítica',
                      child: Row(
                        children: [
                          Icon(Icons.feedback_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Crítica'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Elogio',
                      child: Row(
                        children: [
                          Icon(Icons.favorite_outline, size: 20),
                          SizedBox(width: 12),
                          Text('Elogio'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _contactType = value);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            _buildField(
              controller: _messageController,
              label: 'Mensagem',
              icon: Icons.message_outlined,
              maxLines: 5,
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitSuggestion,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Enviar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// --------------------------------------------------------------------------
  /// Campo padrão de formulário
  /// --------------------------------------------------------------------------
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:ship_rate/data/services/sugestao_service.dart';

/// ============================================================================
/// SugestaoPage
/// ============================================================================
class SugestaoPage extends StatefulWidget {
  const SugestaoPage({super.key});

  @override
  State<SugestaoPage> createState() => _SugestaoPageState();
}

class _SugestaoPageState extends State<SugestaoPage> {
  final _emailController = TextEditingController();
  final _tituloController = TextEditingController();
  final _mensagemController = TextEditingController();

  bool isLoading = false;

  Future<void> _enviar() async {
    setState(() => isLoading = true);

    final ok = await SugestaoService.enviar(
      email: _emailController.text.trim(),
      titulo: _tituloController.text.trim(),
      mensagem: _mensagemController.text.trim(),
    );

    setState(() => isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Sugestão enviada com sucesso!'
            : 'Erro ao enviar sugestão.'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );

    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar Sugestão',
            style: TextStyle(fontWeight: FontWeight.bold)),
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

            _field(
              controller: _emailController,
              label: 'Seu e-mail',
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),
            _field(
              controller: _tituloController,
              label: 'Título da sugestão',
              icon: Icons.title,
            ),
            const SizedBox(height: 16),
            _field(
              controller: _mensagemController,
              label: 'Mensagem',
              icon: Icons.message_outlined,
              maxLines: 5,
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _enviar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Enviar Sugestão',
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

  Widget _field({
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'avaliacao_detalhe_page.dart';

class MinhasAvaliacoesPage extends StatefulWidget {
  const MinhasAvaliacoesPage({super.key});

  @override
  State<MinhasAvaliacoesPage> createState() => _MinhasAvaliacoesPageState();
}

class _MinhasAvaliacoesPageState extends State<MinhasAvaliacoesPage> {
  bool isLoading = true;
  List<_AvaliacaoItem> avaliacoes = [];

  @override
  void initState() {
    super.initState();
    _carregarAvaliacoes();
  }

  Future<void> _carregarAvaliacoes() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final uid = user.uid;

      final userSnap = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      final nomeGuerra = userSnap.data()?['nomeGuerra'];

      final List<_AvaliacaoItem> resultado = [];

      final naviosSnapshot =
          await FirebaseFirestore.instance.collection('navios').get();

      for (final navio in naviosSnapshot.docs) {
        final nomeNavio = navio.data()['nome'] ?? 'Navio';

        final avaliacoesSnapshot =
            await navio.reference.collection('avaliacoes').get();

        for (final avaliacao in avaliacoesSnapshot.docs) {
          final data = avaliacao.data();

          final usuarioIdAvaliacao = data['usuarioId'];
          final nomeGuerraAvaliacao = data['nomeGuerra'];

          final pertenceAoUsuario =
              (usuarioIdAvaliacao != null && usuarioIdAvaliacao == uid) ||
              (usuarioIdAvaliacao == null &&
                  nomeGuerra != null &&
                  nomeGuerraAvaliacao == nomeGuerra);

          if (!pertenceAoUsuario) continue;

          resultado.add(
            _AvaliacaoItem(
              nomeNavio: nomeNavio,
              avaliacao: avaliacao,
            ),
          );
        }
      }

      /// ✅ Ordenação pela DATA DA AVALIAÇÃO
      resultado.sort((a, b) {
        final aData = a.avaliacao['data'] as Timestamp;
        final bData = b.avaliacao['data'] as Timestamp;
        return bData.compareTo(aData);
      });

      setState(() {
        avaliacoes = resultado;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar avaliações: $e');
      setState(() => isLoading = false);
    }
  }

  String _formatarData(Timestamp ts) {
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Avaliações'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : avaliacoes.isEmpty
              ? const Center(
                  child: Text(
                    'Você ainda não avaliou nenhum navio.',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        '📌 Ordenadas da mais recente para a mais antiga',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: avaliacoes.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 28,
                          thickness: 1,
                          color: Colors.black12,
                        ),
                        itemBuilder: (_, i) {
                          final item = avaliacoes[i];
                          final data =
                              item.avaliacao.data() as Map<String, dynamic>;

                          final Timestamp ts = data['data'];

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.directions_boat,
                                color: Colors.indigo,
                              ),
                              title: Text(
                                item.nomeNavio,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Avaliado em ${_formatarData(ts)}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AvaliacaoDetalhePage(
                                      avaliacao: item.avaliacao,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _AvaliacaoItem {
  final String nomeNavio;
  final QueryDocumentSnapshot avaliacao;

  _AvaliacaoItem({
    required this.nomeNavio,
    required this.avaliacao,
  });
}

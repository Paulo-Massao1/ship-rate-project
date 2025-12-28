import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../ratings/add_rating_page.dart';
import '../ships/avaliacao_detalhe_page.dart';

class BuscarAvaliarNavioPage extends StatefulWidget {
  const BuscarAvaliarNavioPage({super.key});

  @override
  State<BuscarAvaliarNavioPage> createState() =>
      _BuscarAvaliarNavioPageState();
}

class _BuscarAvaliarNavioPageState extends State<BuscarAvaliarNavioPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Avaliação de Navios',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pesquise avaliações ou registre sua experiência',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(20),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black87,
                tabs: const [
                  Tab(text: 'Buscar'),
                  Tab(text: 'Avaliar'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  BuscarNavioTab(),
                  AvaliarNavioTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------------------
/// BuscarNavioTab
/// -----------------------------------------------------------------------------
class BuscarNavioTab extends StatefulWidget {
  const BuscarNavioTab({super.key});

  @override
  State<BuscarNavioTab> createState() => _BuscarNavioTabState();
}

class _BuscarNavioTabState extends State<BuscarNavioTab> {
  final TextEditingController _controller = TextEditingController();

  List<QueryDocumentSnapshot> sugestoes = [];
  QueryDocumentSnapshot? navioSelecionado;
  List<QueryDocumentSnapshot>? avaliacoes;

  /// 🔥 BUSCA COMPATÍVEL (navios novos + antigos)
  Future<void> _atualizarSugestoes(String texto) async {
    if (texto.isEmpty) {
      setState(() {
        sugestoes = [];
        navioSelecionado = null;
        avaliacoes = null;
      });
      return;
    }

    final termo = texto.toLowerCase().trim();
    final Map<String, QueryDocumentSnapshot> resultado = {};

    /// 1️⃣ NAVIOS NOVOS (/navios)
    final naviosSnap =
        await FirebaseFirestore.instance.collection('navios').get();

    for (final doc in naviosSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final nome = (data['nome'] ?? '').toString().toLowerCase();
      final imo = (data['imo'] ?? '').toString().toLowerCase();

      if (nome.contains(termo) || (imo.isNotEmpty && imo.contains(termo))) {
        resultado[doc.id] = doc;
      }
    }

    /// 2️⃣ NAVIOS ANTIGOS (collectionGroup de avaliações)
    final avaliacoesSnap =
        await FirebaseFirestore.instance.collectionGroup('avaliacoes').get();

    for (final doc in avaliacoesSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;

      final nomeNavio =
          (data['nomeNavio'] ??
                  data['navio'] ??
                  data['nome'] ??
                  '')
              .toString()
              .toLowerCase();

      if (nomeNavio.isEmpty || !nomeNavio.contains(termo)) continue;

      final navioRef = doc.reference.parent.parent;
      if (navioRef == null) continue;

      final navioSnap = await navioRef.get();
      if (navioSnap.exists && !resultado.containsKey(navioSnap.id)) {
        resultado[navioSnap.id] =
            navioSnap as QueryDocumentSnapshot;
      }
    }

    setState(() {
      sugestoes = resultado.values.toList();
    });
  }

  Future<void> _selecionarNavio(QueryDocumentSnapshot doc) async {
    final snap = await FirebaseFirestore.instance
        .collection('navios')
        .doc(doc.id)
        .collection('avaliacoes')
        .get();

    final lista = snap.docs;

    lista.sort((a, b) {
      final Timestamp aData =
          (a.data() as Map)['dataDesembarque'] ??
              (a.data() as Map)['data'];
      final Timestamp bData =
          (b.data() as Map)['dataDesembarque'] ??
              (b.data() as Map)['data'];
      return bData.compareTo(aData);
    });

    setState(() {
      navioSelecionado = doc;
      avaliacoes = lista;
      sugestoes = [];
      _controller.text = (doc.data() as Map)['nome'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          onChanged: _atualizarSugestoes,
          decoration: InputDecoration(
            hintText: 'Buscar por nome do navio ou IMO',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        if (sugestoes.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: sugestoes.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (_, i) {
                final doc = sugestoes[i];
                return ListTile(
                  leading: const Icon(Icons.directions_boat),
                  title: Text((doc.data() as Map)['nome']),
                  onTap: () => _selecionarNavio(doc),
                );
              },
            ),
          ),

        const SizedBox(height: 12),

        if (navioSelecionado != null && avaliacoes != null)
          Expanded(
            child: ListView(
              children: [
                _ResumoNavioCard(navio: navioSelecionado!),

                const SizedBox(height: 20),
                const Text(
                  'Avaliações',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  '🕒 Ordenadas da mais recente para a mais antiga',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 12),

                _ListaAvaliacoes(avaliacoes: avaliacoes!),
              ],
            ),
          ),
      ],
    );
  }
}

/// -----------------------------------------------------------------------------
/// Lista de Avaliações
/// -----------------------------------------------------------------------------
class _ListaAvaliacoes extends StatelessWidget {
  final List<QueryDocumentSnapshot> avaliacoes;

  const _ListaAvaliacoes({required this.avaliacoes});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: avaliacoes.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final nome = data['nomeGuerra'] ?? 'Prático';
        final Timestamp ts =
            (data['dataDesembarque'] ?? data['data']) as Timestamp;
        final date = ts.toDate();

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(
              'Prático: $nome',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Desembarque: ${_formatDate(date)}'),
                const SizedBox(height: 4),
                const Text(
                  'Ver avaliação',
                  style: TextStyle(
                    color: Colors.indigo,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AvaliacaoDetalhePage(avaliacao: doc),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  static String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

/// -----------------------------------------------------------------------------
/// Resumo do Navio
/// -----------------------------------------------------------------------------
class _ResumoNavioCard extends StatelessWidget {
  final QueryDocumentSnapshot navio;

  const _ResumoNavioCard({required this.navio});

  Widget _chip(String text) {
    return Chip(
      label: Text(text),
      backgroundColor: Colors.indigo.withOpacity(0.08),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = navio.data() as Map<String, dynamic>;
    final medias = (data['medias'] ?? {}) as Map<String, dynamic>;
    final info = (data['info'] ?? {}) as Map<String, dynamic>;

    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['nome'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            const Text('ℹ️ Informações Gerais',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (info['nacionalidadeTripulacao'] != null)
                  _chip('👥 Tripulação: ${info['nacionalidadeTripulacao']}'),
                if (info['numeroCabines'] != null)
                  _chip('🛏️ Cabines: ${info['numeroCabines']}'),
                if (info['frigobar'] != null)
                  _chip('🧊 Frigobar: ${info['frigobar'] ? 'Sim' : 'Não'}'),
                if (info['pia'] != null)
                  _chip('🚰 Pia: ${info['pia'] ? 'Sim' : 'Não'}'),
              ],
            ),

            const Divider(height: 32),

            const Text('📊 Médias das Avaliações',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (medias['temp_cabine'] != null)
                  _chip('🌡️ Temp. Cabine: ${medias['temp_cabine']}'),
                if (medias['limpeza_cabine'] != null)
                  _chip('🧼 Limpeza: ${medias['limpeza_cabine']}'),
                if (medias['passadico_equip'] != null)
                  _chip('🧭 Equip. Passadiço: ${medias['passadico_equip']}'),
                if (medias['passadico_temp'] != null)
                  _chip('🌬️ Temp. Passadiço: ${medias['passadico_temp']}'),
                if (medias['comida'] != null)
                  _chip('🍽️ Comida: ${medias['comida']}'),
                if (medias['relacionamento'] != null)
                  _chip('🤝 Relação: ${medias['relacionamento']}'),
                if (medias['dispositivo'] != null)
                  _chip('⚓ Dispositivo: ${medias['dispositivo']}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------------------
/// AvaliarNavioTab
/// -----------------------------------------------------------------------------
class AvaliarNavioTab extends StatelessWidget {
  const AvaliarNavioTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.rate_review),
        label: const Text('Avaliar um navio'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddRatingPage(imo: ''),
            ),
          );
        },
      ),
    );
  }
}

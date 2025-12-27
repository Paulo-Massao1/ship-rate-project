import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../ratings/add_rating_page.dart';

/// -----------------------------------------------------------------------------
/// BuscarAvaliarNavioPage
/// -----------------------------------------------------------------------------
/// Tela principal da feature de navios.
///
/// Funções principais:
///  • Apresenta duas abas (buscar / avaliar).
///  • Busca com autocomplete profissional.
///  • Exibe card completo SOMENTE após seleção do navio.
/// -----------------------------------------------------------------------------
class BuscarAvaliarNavioPage extends StatefulWidget {
  const BuscarAvaliarNavioPage({super.key});

  @override
  State<BuscarAvaliarNavioPage> createState() => _BuscarAvaliarNavioPageState();
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

  Future<void> _atualizarSugestoes(String texto) async {
    if (texto.isEmpty) {
      setState(() {
        sugestoes = [];
        navioSelecionado = null;
        avaliacoes = null;
      });
      return;
    }

    final snapshot =
        await FirebaseFirestore.instance.collection('navios').get();

    setState(() {
      sugestoes = snapshot.docs.where((doc) {
        final nome = doc['nome'].toString().toLowerCase();
        return nome.contains(texto.toLowerCase());
      }).toList();
    });
  }

  Future<void> _selecionarNavio(QueryDocumentSnapshot doc) async {
    final avaliacoesSnapshot = await FirebaseFirestore.instance
        .collection('navios')
        .doc(doc.id)
        .collection('avaliacoes')
        .get();

    setState(() {
      navioSelecionado = doc;
      avaliacoes = avaliacoesSnapshot.docs;
      sugestoes = [];
      _controller.text = doc['nome'];
    });
  }

  /// ---------------------------------------------------------------------------
  /// Negrita SOMENTE a primeira ocorrência do texto buscado
  /// ---------------------------------------------------------------------------
  Widget _highlightMatch(String text, String query) {
    if (query.isEmpty) return Text(text);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    final index = lowerText.indexOf(lowerQuery);
    if (index < 0) return Text(text);

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 16),
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          onChanged: _atualizarSugestoes,
          decoration: InputDecoration(
            hintText: 'Buscar por nome do navio',
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
                  title: _highlightMatch(doc['nome'], _controller.text),
                  onTap: () => _selecionarNavio(doc),
                );
              },
            ),
          ),

        const SizedBox(height: 12),

        if (navioSelecionado != null)
          Expanded(
            child: _CardNavio(
              navio: navioSelecionado!,
              avaliacoes: avaliacoes,
            ),
          ),
      ],
    );
  }
}

/// -----------------------------------------------------------------------------
/// Card do Navio (DESIGN RESTAURADO COM CONTAINERS)
/// -----------------------------------------------------------------------------
class _CardNavio extends StatelessWidget {
  final QueryDocumentSnapshot navio;
  final List<QueryDocumentSnapshot>? avaliacoes;

  const _CardNavio({
    required this.navio,
    required this.avaliacoes,
  });

  @override
  Widget build(BuildContext context) {
    final data = navio.data() as Map<String, dynamic>;
    final medias = (data['medias'] ?? {}) as Map;

    return ListView(
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['nome'],
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  data['imo'] == null || data['imo'].toString().isEmpty
                      ? 'IMO: Não informado'
                      : 'IMO: ${data['imo']}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),

        _section(
          title: 'Passadiço',
          content: Wrap(
            spacing: 8,
            children: [
              Chip(label: Text('Frigobar: ${data['frigobar'] ?? '—'}')),
              Chip(label: Text('Pia: ${data['pia'] ?? '—'}')),
            ],
          ),
        ),

        _section(
          title: 'Informações Gerais',
          content: Wrap(
            spacing: 8,
            children: [
              Chip(label: Text('Tripulação: ${data['tripulacao'] ?? '—'}')),
              Chip(label: Text('Cabines: ${data['cabines'] ?? '—'}')),
            ],
          ),
        ),

        if (medias.isNotEmpty)
          _section(
            title: 'Médias',
            content: Wrap(
              spacing: 8,
              children: medias.entries
                  .map((e) => Chip(label: Text('${e.key}: ${e.value}')))
                  .toList(),
            ),
          ),

        if (avaliacoes != null && avaliacoes!.isNotEmpty)
          _section(
            title: 'Avaliado por',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: avaliacoes!
                  .map(
                    (doc) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        'Prático: ${(doc.data() as Map)['nomeGuerra'] ?? '—'}',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _section({required String title, required Widget content}) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            content,
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

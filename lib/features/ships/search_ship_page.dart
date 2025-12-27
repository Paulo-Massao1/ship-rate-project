import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../ratings/add_rating_page.dart';

/// -----------------------------------------------------------------------------
/// BuscarAvaliarNavioPage
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
          children: [
            const SizedBox(height: 10),
            const Text(
              'Avaliação de Navios',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pesquise avaliações ou registre sua experiência',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black,
                indicator: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(30),
                ),
                tabs: const [
                  Tab(text: 'Buscar'),
                  Tab(text: 'Avaliar'),
                ],
              ),
            ),
            const SizedBox(height: 10),
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
  final TextEditingController buscaController = TextEditingController();

  Map<String, dynamic>? navioEncontrado;
  List<QueryDocumentSnapshot>? avaliacoes;
  List<String> nomesNavios = [];

  @override
  void initState() {
    super.initState();
    _carregarNomesNavios();
  }

  Future<void> _carregarNomesNavios() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('navios').get();

    nomesNavios = snapshot.docs
        .map((doc) => doc.data()['nome'].toString())
        .toList();

    setState(() {});
  }

  Future<void> buscarNavio() async {
    final busca = buscaController.text.trim();
    if (busca.isEmpty) return;

    final snapshot = await FirebaseFirestore.instance.collection('navios').get();

    for (var doc in snapshot.docs) {
      final data = doc.data();

      if (data['nome'].toString().toLowerCase() == busca.toLowerCase() ||
          data['imo']?.toString() == busca) {
        setState(() => navioEncontrado = data);

        final avaliacoesSnapshot = await FirebaseFirestore.instance
            .collection('navios')
            .doc(doc.id)
            .collection('avaliacoes')
            .get();

        setState(() => avaliacoes = avaliacoesSnapshot.docs);
        return;
      }
    }

    setState(() {
      navioEncontrado = null;
      avaliacoes = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navio não encontrado.')),
    );
  }

  /// ---------------------------------------------------------------------------
  /// Cria texto com destaque da substring digitada
  /// ---------------------------------------------------------------------------
  RichText _highlightMatch(String text, String query) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    if (!lowerText.contains(lowerQuery)) {
      return RichText(text: TextSpan(text: text, style: const TextStyle(color: Colors.black)));
    }

    final start = lowerText.indexOf(lowerQuery);
    final end = start + query.length;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text.substring(0, start),
            style: const TextStyle(color: Colors.black),
          ),
          TextSpan(
            text: text.substring(start, end),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: text.substring(end),
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue value) {
              final query = value.text.toLowerCase();
              if (query.isEmpty) return const Iterable<String>.empty();

              return nomesNavios.where(
                (nome) => nome.toLowerCase().contains(query),
              );
            },
            onSelected: (String selection) {
              buscaController.text = selection;
              buscarNavio();
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Buscar por nome ou IMO',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onChanged: (value) {
                  buscaController.text = value;
                },
                onSubmitted: (_) => buscarNavio(),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              final query = buscaController.text;

              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: _highlightMatch(option, query),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Buscar'),
              onPressed: buscarNavio,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: navioEncontrado != null
                ? _CardNavio(
                    navio: navioEncontrado!,
                    avaliacoes: avaliacoes,
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------------
/// _CardNavio
/// -----------------------------------------------------------------------------
class _CardNavio extends StatelessWidget {
  final Map<String, dynamic> navio;
  final List<QueryDocumentSnapshot>? avaliacoes;

  const _CardNavio({
    required this.navio,
    required this.avaliacoes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              navio['nome'],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            if (avaliacoes != null && avaliacoes!.isNotEmpty) ...[
              const Divider(),
              const Text(
                "Avaliado por:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              for (var doc in avaliacoes!)
                Text("• Prático: ${doc['nomeGuerra'] ?? 'Prático'}"),
            ]
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
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddRatingPage(imo: ''),
            ),
          );

          if (!context.mounted) return;

          if (result == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Avaliação salva com sucesso'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }
}

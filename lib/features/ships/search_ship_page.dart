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
///  • Gera uma interface simples e responsiva.
///  • Renderiza o componente de busca e avaliação.
///
/// O TabController controla a troca entre as duas telas.
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

    /// Define 2 abas:
    ///  - buscar navios
    ///  - avaliar navios
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),

            /// Título principal
            const Text(
              'Avaliação de Navios',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            /// Subtítulo explicativo
            const Text(
              'Pesquise avaliações ou registre sua experiência',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),

            const SizedBox(height: 12),

            /// Menu de abas
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

            /// Conteúdo das abas
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
/// Tela responsável por buscar navios.
///  • Busca simples por nome ou IMO.
///  • Renderiza card com dados do navio.
///  • Exibe avaliações e nomes dos práticos.
///
/// Obs: busca sem índice — adequada para pequeno volume.
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

  /// Executa busca por nome ou imo
  Future<void> buscarNavio() async {
    final busca = buscaController.text.trim();
    if (busca.isEmpty) return;

    final snapshot = await FirebaseFirestore.instance.collection('navios').get();

    for (var doc in snapshot.docs) {
      final data = doc.data();

      /// match nome ou IMO
      if (data['nome'].toString().toLowerCase() == busca.toLowerCase() ||
          data['imo']?.toString() == busca) {
        
        setState(() => navioEncontrado = data);

        /// CORREÇÃO IMPORTANTE:
        /// buscar avaliações usando doc.id e NÃO data['imo']
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          TextField(
            controller: buscaController,
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou IMO',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onSubmitted: (_) => buscarNavio(),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Buscar'),
              onPressed: buscarNavio,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
              ),
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
/// Widget que exibe:
///  • dados do navio
///  • equipamentos
///  • médias
///  • E PRINCIPALMENTE: nomes dos práticos/avaliadores
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
    final medias = (navio['medias'] ?? {}) as Map;

    final temFrigobar = navio['frigobar'] ?? 'Não informado';
    final temPia = navio['pia'] ?? 'Não informado';
    final trip = navio['tripulacao'] ?? 'Não informada';
    final cabines = navio['cabines']?.toString() ?? 'Não informado';

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
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              navio['imo'] == null || navio['imo'].toString().isEmpty
                  ? 'IMO: Não informado'
                  : 'IMO: ${navio['imo']}',
              style: const TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 14),

            const Text("Passadiço", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),

            Wrap(
              spacing: 6,
              children: [
                Chip(label: Text('Frigobar: $temFrigobar')),
                Chip(label: Text('Pia: $temPia')),
              ],
            ),

            const SizedBox(height: 14),

            const Text("Informações Gerais", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),

            Wrap(
              spacing: 6,
              children: [
                Chip(label: Text('Tripulação: $trip')),
                Chip(label: Text('Cabines: $cabines')),
              ],
            ),

            const SizedBox(height: 14),

            if (medias.isNotEmpty) ...[
              const Text("Médias", style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 6,
                children: [
                  for (var entry in medias.entries)
                    Chip(label: Text('${entry.key}: ${entry.value}')),
                ],
              ),
            ],

            const SizedBox(height: 20),

            /// EXIBIÇÃO DOS PRÁTICOS
            if (avaliacoes != null && avaliacoes!.isNotEmpty) ...[
              const Divider(),
              const Text("Avaliado por:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),

              for (var doc in avaliacoes!) ...[
                Builder(
                  builder: (_) {
                    final map = doc.data() as Map<String, dynamic>;
                    final nome = map['nomeGuerra'] ?? 'Prático';
                    return Text("• Prático: $nome");
                  },
                )
              ]
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

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
///  • Gera uma interface simples e responsiva de navegação.
///  • Renderiza o componente de busca e avaliação.
///
/// TabController controla a troca entre telas.
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

    /// Define um controlador com 2 abas:
    ///  - Buscar
    ///  - Avaliar
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

            /// Título da página
            const Text(
              'Avaliação de Navios',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            /// Subtítulo informativo
            const Text(
              'Pesquise avaliações ou registre sua experiência',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 12),

            /// Seletor de abas com design customizado
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
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: EdgeInsets.zero,
                tabs: const [
                  Tab(text: 'Buscar'),
                  Tab(text: 'Avaliar'),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// Conteúdo renderizado conforme aba selecionada
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
/// Tela dedicada à busca de navios.
///
/// Regras:
///  • Pesquisa simples pelo campo nome ou IMO.
///  • Busca feita via Firestore.
///  • Se encontrado, renderiza card com dados.
///  • Caso contrário, mostra aviso.
///
/// NÃO faz busca paginada ou por índice (FireStore não indexado).
/// Esse design é adequado para base pequena; pode ser otimizado usando where.
/// -----------------------------------------------------------------------------
class BuscarNavioTab extends StatefulWidget {
  const BuscarNavioTab({super.key});

  @override
  State<BuscarNavioTab> createState() => _BuscarNavioTabState();
}

class _BuscarNavioTabState extends State<BuscarNavioTab> {
  /// Controller do campo de texto de busca
  final TextEditingController buscaController = TextEditingController();

  /// Guarda o navio encontrado (se existir)
  Map<String, dynamic>? navioEncontrado;

  /// Guarda avaliações carregadas do Firestore
  List<QueryDocumentSnapshot>? avaliacoes;

  /// Executa a busca pelo nome ou IMO
  Future<void> buscarNavio() async {
    final busca = buscaController.text.trim();
    if (busca.isEmpty) return;

    final snapshot = await FirebaseFirestore.instance.collection('navios').get();

    /// Iteração local na coleção (ideal apenas para dataset pequeno)
    for (var doc in snapshot.docs) {
      final data = doc.data();

      /// Match por nome (case insensitive) ou por IMO
      if (data['nome'].toString().toLowerCase() == busca.toLowerCase() ||
          data['imo']?.toString() == busca) {
        
        /// Atualiza interface para exibir card
        setState(() => navioEncontrado = data);

        /// Carrega avaliações relacionadas
        final avaliacoesSnapshot = await FirebaseFirestore.instance
            .collection('navios')
            .doc(data['imo'])
            .collection('avaliacoes')
            .get();

        setState(() => avaliacoes = avaliacoesSnapshot.docs);
        return;
      }
    }

    /// Não encontrado: reset estado + snackbar
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
          /// Input de busca
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

          /// Botão "Buscar"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Buscar'),
              onPressed: buscarNavio,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// Exibição condicional:
          /// - Se navio encontrado → renderiza card
          /// - Caso contrário → apenas espaço vazio
          Expanded(
            child: navioEncontrado != null
                ? _CardNavio(navio: navioEncontrado!, avaliacoes: avaliacoes)
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
/// Widget responsável por exibir:
///  • dados estruturais do navio
///  • equipamentos (frigobar/pia)
///  • tripulação / cabines
///  • médias agregadas
///  • lista de avaliadores (nome de guerra)
///
/// É usado apenas pela aba de busca.
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
      margin: const EdgeInsets.only(top: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Nome do navio
            Text(
              navio['nome'],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            /// IMO (pode ser não informado)
            Text(
              navio['imo'] == null || navio['imo'].toString().isEmpty
                  ? 'IMO: Não informado'
                  : 'IMO: ${navio['imo']}',
              style: const TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 14),

            /// Informações do passadiço
            const Text(
              "Passadiço",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            Wrap(
              spacing: 6,
              children: [
                Chip(
                  label: Text('Frigobar: $temFrigobar'),
                  backgroundColor: Colors.indigo.shade50,
                ),
                Chip(
                  label: Text('Pia: $temPia'),
                  backgroundColor: Colors.indigo.shade50,
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// Tripulação e cabines
            const Text(
              "Informações Gerais",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            Wrap(
              spacing: 6,
              children: [
                Chip(
                  label: Text('Tripulação: $trip'),
                  backgroundColor: Colors.grey.shade200,
                ),
                Chip(
                  label: Text('Cabines: $cabines'),
                  backgroundColor: Colors.grey.shade200,
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// Médias agregadas
            if (medias.isNotEmpty) ...[
              const Text(
                "Médias das Avaliações",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  for (var entry in medias.entries)
                    Chip(
                      label: Text('${entry.key}: ${entry.value}'),
                      backgroundColor: Colors.blue.shade50,
                    ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            /// Lista de avaliadores
            if (avaliacoes != null && avaliacoes!.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Avaliado por:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              for (var doc in avaliacoes!)
                Text("• ${doc['nomeGuerra'] ?? 'Prático'}"),
            ],
          ],
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------------------
/// AvaliarNavioTab
/// -----------------------------------------------------------------------------
/// Exibe CTA simples com botão para ir à AddRatingPage.
///
/// NÃO contém lógica de cadastro.
/// Apenas encaminha para fluxo de avaliação.
/// -----------------------------------------------------------------------------
class AvaliarNavioTab extends StatelessWidget {
  const AvaliarNavioTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        /// Ícone central
        Icon(
          Icons.directions_boat_filled_rounded,
          color: Colors.indigo,
          size: 80,
        ),

        const SizedBox(height: 16),

        const Text(
          'Ainda não avaliou um navio?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Clique no botão abaixo para registrar sua experiência.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 28),

        /// Botão → abre AddRatingPage
        ElevatedButton.icon(
          icon: const Icon(Icons.rate_review),
          label: const Text('Avaliar um navio'),
          onPressed: () async {
            final resultado = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddRatingPage(imo: ''),
              ),
            );

            if (!context.mounted) return;

            /// Feedback caso o salvamento tenha sido bem-sucedido
            if (resultado == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Avaliação salva com sucesso'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ],
    );
  }
}

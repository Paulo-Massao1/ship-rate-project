import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'rating_detail_page.dart';

/// ============================================================================
/// MY RATINGS PAGE
/// ============================================================================
/// Tela que exibe todas as avaliações realizadas pelo usuário autenticado.
///
/// Funcionalidades:
/// ----------------
/// • Lista todas as avaliações do usuário logado
/// • Ordenação da mais recente para a mais antiga
/// • Navegação para detalhes de cada avaliação
/// • Busca distribuída (percorre todos os navios)
///
/// Lógica de Busca:
/// ----------------
/// 1. Busca todos os navios da coleção `navios`
/// 2. Para cada navio, busca subcoleção `avaliacoes`
/// 3. Filtra avaliações pelo usuário atual (por UID ou nome de guerra)
/// 4. Ordena por data de criação (mais recente primeiro)
///
/// Compatibilidade:
/// ----------------
/// • Avaliações antigas: usa campo `data` (legado)
/// • Avaliações novas: usa campo `createdAt` (servidor)
/// • Identifica usuário por `usuarioId` ou `nomeGuerra` (fallback)
///
class MyRatingsPage extends StatefulWidget {
  const MyRatingsPage({super.key});

  @override
  State<MyRatingsPage> createState() => _MyRatingsPageState();
}

class _MyRatingsPageState extends State<MyRatingsPage> {
  /// Estado de carregamento
  bool _isLoading = true;

  /// Lista de avaliações do usuário
  final List<_RatingItem> _ratings = [];

  /// --------------------------------------------------------------------------
  /// Inicialização
  /// --------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _loadUserRatings();
  }

  /// --------------------------------------------------------------------------
  /// Carrega todas as avaliações do usuário autenticado
  /// --------------------------------------------------------------------------
  /// Fluxo de execução:
  ///   1. Verifica autenticação do usuário
  ///   2. Busca nome de guerra do usuário no Firestore
  ///   3. Percorre todos os navios
  ///   4. Para cada navio, busca subcoleção de avaliações
  ///   5. Filtra avaliações do usuário atual
  ///   6. Ordena por data (mais recente primeiro)
  ///
  /// Critério de Filtro:
  ///   • Por UID: usuarioId == uid (método preferencial)
  ///   • Por nome de guerra: fallback para avaliações antigas
  ///
  /// Observações:
  ///   • Operação distribuída (não há índice centralizado)
  ///   • Pode ser lenta com muitos navios cadastrados
  ///   • TODO: Implementar paginação se necessário
  Future<void> _loadUserRatings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final uid = user.uid;

      /// Busca nome de guerra do usuário
      final userSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      final String? callSign = userSnapshot.data()?['nomeGuerra'];

      final List<_RatingItem> results = [];

      /// Busca todos os navios
      final shipsSnapshot =
          await FirebaseFirestore.instance.collection('navios').get();

      /// Percorre cada navio
      for (final ship in shipsSnapshot.docs) {
        final shipName = ship.data()['nome'] ?? 'Navio';

        /// Busca avaliações do navio
        final ratingsSnapshot =
            await ship.reference.collection('avaliacoes').get();

        /// Filtra avaliações do usuário atual
        for (final rating in ratingsSnapshot.docs) {
          final data = rating.data();

          final ratingUserId = data['usuarioId'];
          final ratingCallSign = data['nomeGuerra'];

          /// Critério de filtro:
          /// 1. Preferência: usuarioId == uid
          /// 2. Fallback: nomeGuerra == callSign (avaliações antigas)
          final belongsToUser =
              (ratingUserId != null && ratingUserId == uid) ||
              (ratingUserId == null &&
                  callSign != null &&
                  ratingCallSign == callSign);

          if (!belongsToUser) continue;

          results.add(
            _RatingItem(
              shipName: shipName,
              rating: rating,
            ),
          );
        }
      }

      /// Ordenação robusta por data (mais recente primeiro)
      /// Prioridade: createdAt > data (legado)
      results.sort((a, b) {
        final aDate = _resolveRatingDate(
          a.rating.data() as Map<String, dynamic>,
        );
        final bDate = _resolveRatingDate(
          b.rating.data() as Map<String, dynamic>,
        );
        return bDate.compareTo(aDate);
      });

      setState(() {
        _ratings
          ..clear()
          ..addAll(results);
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('❌ Erro ao carregar avaliações: $error');
      setState(() => _isLoading = false);
    }
  }

  /// --------------------------------------------------------------------------
  /// Resolve data correta da avaliação
  /// --------------------------------------------------------------------------
  /// Prioridade de campos:
  ///   1. createdAt (timestamp do servidor - preferencial)
  ///   2. data (campo legado - fallback)
  ///
  /// Retorno:
  ///   • DateTime da avaliação
  ///   • DateTime epoch (1970) se não encontrar data válida
  DateTime _resolveRatingDate(Map<String, dynamic> data) {
    final ts = data['createdAt'] ?? data['data'];

    if (ts is Timestamp) {
      return ts.toDate();
    }

    /// Fallback: data inválida retorna epoch
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// --------------------------------------------------------------------------
  /// Formata data para exibição
  /// --------------------------------------------------------------------------
  /// Formato: dd/MM/yyyy
  ///
  /// Exemplo: 29/12/2025
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// --------------------------------------------------------------------------
  /// Build principal
  /// --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Avaliações'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ratings.isEmpty
              ? const Center(
                  child: Text(
                    'Você ainda não avaliou nenhum navio.',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Hint de ordenação
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

                    /// Lista de avaliações
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _ratings.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 28,
                          thickness: 1,
                          color: Colors.black12,
                        ),
                        itemBuilder: (_, index) {
                          final item = _ratings[index];
                          final data =
                              item.rating.data() as Map<String, dynamic>;

                          final ratingDate = _resolveRatingDate(data);

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
                                item.shipName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Avaliado em ${_formatDate(ratingDate)}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RatingDetailPage(
                                      rating: item.rating,
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

/// ============================================================================
/// RATING ITEM (Modelo Interno)
/// ============================================================================
/// Modelo de dados interno para representar item da lista de avaliações.
///
/// Campos:
///   • [shipName] - Nome do navio avaliado
///   • [rating] - Documento da avaliação no Firestore
///
class _RatingItem {
  /// Nome do navio
  final String shipName;

  /// Documento da avaliação
  final QueryDocumentSnapshot rating;

  _RatingItem({
    required this.shipName,
    required this.rating,
  });
}
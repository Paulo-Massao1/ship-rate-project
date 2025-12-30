import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// ============================================================================
/// RATING DETAIL PAGE
/// ============================================================================
/// Tela de visualização detalhada de uma avaliação de navio.
///
/// Funcionalidades:
/// ----------------
/// • Exibe todos os dados da avaliação
/// • Mostra informações do navio (nome, IMO)
/// • Apresenta datas (avaliação e desembarque)
/// • Lista informações da cabine
/// • Exibe avaliações por categoria com notas
/// • Mostra observações gerais
///
/// Características:
/// ----------------
/// • Página SOMENTE leitura (não permite edições)
/// • Busca dados do navio no documento pai
/// • Agrupa critérios por categoria (Cabine, Passadiço, Outros)
/// • Layout limpo e profissional com Cards
///
/// Estrutura de Dados:
/// -------------------
/// Recebe um [QueryDocumentSnapshot] da avaliação e busca dados do navio
/// através da referência pai (navios/{navioId}/avaliacoes/{avaliacaoId})
///
class RatingDetailPage extends StatelessWidget {
  /// Documento da avaliação do Firestore
  final QueryDocumentSnapshot rating;

  const RatingDetailPage({
    super.key,
    required this.rating,
  });

  /// --------------------------------------------------------------------------
  /// Formata Timestamp para exibição
  /// --------------------------------------------------------------------------
  /// Formato: dd/MM/yyyy
  ///
  /// Exemplo: 29/12/2025
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// --------------------------------------------------------------------------
  /// Build principal
  /// --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = rating.data() as Map<String, dynamic>;

    final String callSign = data['nomeGuerra'] ?? 'Prático';
    final Timestamp? ratingDate = data['data'];
    final Timestamp? disembarkationDate = data['dataDesembarque'];
    final String cabinType = data['tipoCabine'] ?? '';
    final String generalObservations =
        (data['observacaoGeral'] ?? '').toString();

    final Map<String, dynamic> ratingItems =
        Map<String, dynamic>.from(data['itens'] ?? {});

    final Map<String, dynamic> shipInfo =
        Map<String, dynamic>.from(data['infoNavio'] ?? {});

    /// Referência ao documento pai (navio)
    final DocumentReference shipRef = rating.reference.parent.parent!;

    return FutureBuilder<DocumentSnapshot>(
      future: shipRef.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Erro ao carregar dados do navio'),
            ),
          );
        }

        final Map<String, dynamic>? shipData =
            snapshot.data?.data() as Map<String, dynamic>?;

        final String shipName = shipData?['nome'] ?? 'Navio';
        final String? imo = shipData?['imo'];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalhes da Avaliação'),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// ---------------------------------------------------------------
              /// Cabeçalho com informações principais
              /// ---------------------------------------------------------------
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shipName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      if (imo != null && imo.isNotEmpty) Text('IMO: $imo'),

                      if (ratingDate != null)
                        Text(
                          'Avaliado em: ${_formatDate(ratingDate)}',
                          style: const TextStyle(
                            color: Colors.black54,
                          ),
                        ),

                      if (disembarkationDate != null)
                        Text(
                          'Data de desembarque: ${_formatDate(disembarkationDate)}',
                          style: const TextStyle(
                            color: Colors.black54,
                          ),
                        ),

                      if (cabinType.isNotEmpty)
                        Text('Tipo da cabine: $cabinType'),

                      const SizedBox(height: 6),

                      Text(
                        'Prático: $callSign',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// ---------------------------------------------------------------
              /// Informações do Navio
              /// ---------------------------------------------------------------
              if (shipInfo.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informações do Navio',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (shipInfo['nacionalidadeTripulacao'] != null)
                          _buildInfoRow(
                            'Tripulação',
                            shipInfo['nacionalidadeTripulacao'],
                          ),

                        if (shipInfo['numeroCabines'] != null &&
                            shipInfo['numeroCabines'] > 0)
                          _buildInfoRow(
                            'Cabines',
                            shipInfo['numeroCabines'].toString(),
                          ),

                        if (shipInfo['frigobar'] != null)
                          _buildInfoRow(
                            'Frigobar',
                            shipInfo['frigobar'] ? 'Sim' : 'Não',
                          ),

                        if (shipInfo['pia'] != null)
                          _buildInfoRow(
                            'Pia',
                            shipInfo['pia'] ? 'Sim' : 'Não',
                          ),
                      ],
                    ),
                  ),
                ),
              ],

              /// ---------------------------------------------------------------
              /// Observações Gerais
              /// ---------------------------------------------------------------
              if (generalObservations.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: const Text(
                      'Observações Gerais',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(generalObservations),
                ),
              ],

              const SizedBox(height: 24),

              /// ---------------------------------------------------------------
              /// Critérios de Avaliação - Cabine
              /// ---------------------------------------------------------------
              _buildSectionTitle('Cabine'),
              ..._buildRatingItems(ratingItems, [
                'Temperatura da Cabine',
                'Limpeza da Cabine',
              ]),

              /// ---------------------------------------------------------------
              /// Critérios de Avaliação - Passadiço
              /// ---------------------------------------------------------------
              _buildSectionTitle('Passadiço'),
              ..._buildRatingItems(ratingItems, [
                'Passadiço – Equipamentos',
                'Passadiço – Temperatura',
              ]),

              /// ---------------------------------------------------------------
              /// Critérios de Avaliação - Outros
              /// ---------------------------------------------------------------
              _buildSectionTitle('Outros'),
              ..._buildRatingItems(ratingItems, [
                'Dispositivo de Embarque/Desembarque',
                'Comida',
                'Relacionamento com comandante/tripulação',
              ]),
            ],
          ),
        );
      },
    );
  }

  /// --------------------------------------------------------------------------
  /// Widgets auxiliares
  /// --------------------------------------------------------------------------

  /// Título de seção
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }

  /// Constrói lista de cards de critérios de avaliação
  /// 
  /// Parâmetros:
  ///   • [items] - Map com todos os itens avaliados
  ///   • [order] - Lista com ordem de exibição dos critérios
  /// 
  /// Retorno:
  ///   • Lista de Widgets (Cards) para cada critério
  List<Widget> _buildRatingItems(
    Map<String, dynamic> items,
    List<String> order,
  ) {
    return order.where(items.containsKey).map((name) {
      final Map<String, dynamic> item = Map<String, dynamic>.from(items[name]);

      final dynamic rating = item['nota'];
      final String observation = (item['observacao'] ?? '').toString();

      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Nota: ${rating ?? '-'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo,
                ),
              ),
              if (observation.isNotEmpty) ...[
                const Divider(height: 24),
                Text(observation),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  /// Linha de informação (label: valor)
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
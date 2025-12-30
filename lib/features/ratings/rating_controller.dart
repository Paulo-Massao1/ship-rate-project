import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================================
/// RATING CONTROLLER
/// ============================================================================
/// Controller responsável pela lógica de negócio de avaliações de navios.
///
/// Responsabilidades:
/// ------------------
/// • Criar e salvar avaliações de navios
/// • Criar navio automaticamente caso não exista
/// • Normalizar dados enviados pelo formulário
/// • Recalcular médias agregadas do navio
/// • Buscar navios para autocomplete
///
/// Importante:
/// -----------
/// • NÃO contém lógica de UI
/// • NÃO depende de Widgets
/// • Separação total entre apresentação e negócio
///
/// Estrutura de Dados:
/// -------------------
/// ```
/// navios/{navioId}/
///   - nome: String
///   - imo: String?
///   - medias: Map<String, String>
///   - info: Map<String, dynamic>
///   - avaliacoes/{avaliacaoId}/
///       - usuarioId: String
///       - nomeGuerra: String
///       - dataDesembarque: Timestamp
///       - createdAt: Timestamp (server)
///       - tipoCabine: String
///       - observacaoGeral: String
///       - infoNavio: Map
///       - itens: Map<String, Map>
/// ```
///
class RatingController {
  /// Instância do Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Instância do Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// --------------------------------------------------------------------------
  /// Ordem oficial dos critérios de avaliação
  /// --------------------------------------------------------------------------
  /// ⚠️ CRÍTICO: NÃO alterar sem migrar dados existentes no Firestore
  /// Esta ordem define a estrutura de dados e cálculo de médias
  static const List<String> _ratingCriteria = [
    'Dispositivo de Embarque/Desembarque',
    'Temperatura da Cabine',
    'Limpeza da Cabine',
    'Passadiço – Equipamentos',
    'Passadiço – Temperatura',
    'Comida',
    'Relacionamento com comandante/tripulação',
  ];

  /// --------------------------------------------------------------------------
  /// Carrega lista de navios para autocomplete
  /// --------------------------------------------------------------------------
  /// Retorna lista única de nomes e IMOs de navios cadastrados.
  /// Útil para autocomplete e busca.
  ///
  /// Retorno:
  ///   • Lista de Strings contendo nomes e IMOs únicos
  ///   • Lista vazia se não houver navios cadastrados
  ///
  /// Exemplo:
  /// ```dart
  /// final ships = await controller.loadShips();
  /// // ['MSC Divina', 'MSC Opera', '9876543', ...]
  /// ```
  Future<List<String>> loadShips() async {
    final snapshot = await _firestore.collection('navios').get();
    final names = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = (data['nome'] ?? '').toString().trim();
      final imo = (data['imo'] ?? '').toString().trim();

      if (name.isNotEmpty) names.add(name);
      if (imo.isNotEmpty) names.add(imo);
    }

    return names.toList();
  }

  /// --------------------------------------------------------------------------
  /// Salva avaliação de navio
  /// --------------------------------------------------------------------------
  /// Fluxo de execução:
  ///   1. Valida autenticação do usuário
  ///   2. Busca navio por IMO (prioridade) ou nome
  ///   3. Cria navio se não existir
  ///   4. Busca nome de guerra do prático
  ///   5. Normaliza dados da avaliação
  ///   6. Salva avaliação na subcoleção
  ///   7. Atualiza informações consolidadas do navio
  ///   8. Recalcula médias agregadas
  ///
  /// Parâmetros:
  ///   • [nomeNavio] - Nome do navio
  ///   • [imoInicial] - IMO do navio (opcional)
  ///   • [dataDesembarque] - Data de desembarque do prático
  ///   • [tipoCabine] - Tipo de cabine (PRT, OWNER, etc.)
  ///   • [observacaoGeral] - Observação geral da avaliação
  ///   • [itens] - Map de critérios com notas e observações
  ///   • [infoNavio] - Informações do navio (opcional)
  ///
  /// Exceções:
  ///   • Exception se usuário não estiver autenticado
  ///
  /// Exemplo:
  /// ```dart
  /// await controller.saveRating(
  ///   nomeNavio: 'MSC Divina',
  ///   imoInicial: '9876543',
  ///   dataDesembarque: DateTime.now(),
  ///   tipoCabine: 'PRT',
  ///   observacaoGeral: 'Excelente navio',
  ///   itens: {
  ///     'Comida': {'nota': 5.0, 'observacao': 'Ótima'},
  ///   },
  /// );
  /// ```
  Future<void> salvarAvaliacao({
    required String nomeNavio,
    required String imoInicial,
    required DateTime dataDesembarque,
    required String tipoCabine,
    required String observacaoGeral,
    required Map<String, Map<String, dynamic>> itens,
    Map<String, dynamic>? infoNavio,
  }) async {
    /// Validação de autenticação
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('Usuário não autenticado');
    }

    final shipsRef = _firestore.collection('navios');

    final normalizedName = nomeNavio.trim();
    final normalizedImo = imoInicial.trim();

    /// -----------------------------------------------------------------------
    /// Buscar navio (prioridade: IMO > Nome)
    /// -----------------------------------------------------------------------
    QuerySnapshot<Map<String, dynamic>> query;

    if (normalizedImo.isNotEmpty) {
      query = await shipsRef
          .where('imo', isEqualTo: normalizedImo)
          .limit(1)
          .get();
    } else {
      query = await shipsRef
          .where('nome', isEqualTo: normalizedName)
          .limit(1)
          .get();
    }

    late DocumentReference<Map<String, dynamic>> shipRef;

    if (query.docs.isNotEmpty) {
      /// Navio já existe - usa referência existente
      shipRef = query.docs.first.reference;
    } else {
      /// Navio não existe - cria novo documento
      shipRef = shipsRef.doc();
      await shipRef.set({
        'nome': normalizedName,
        'imo': normalizedImo.isNotEmpty ? normalizedImo : null,
        'medias': {},
        'info': {},
      });
    }

    /// -----------------------------------------------------------------------
    /// Buscar nome de guerra do prático
    /// -----------------------------------------------------------------------
    final userSnapshot =
        await _firestore.collection('usuarios').doc(userId).get();
    final callSign = userSnapshot.data()?['nomeGuerra'] ?? 'Prático';

    /// -----------------------------------------------------------------------
    /// Normalizar itens de avaliação
    /// -----------------------------------------------------------------------
    final normalizedItems = {
      for (final item in _ratingCriteria)
        item: {
          'nota': _toDouble(itens[item]?['nota']),
          'observacao': (itens[item]?['observacao'] ?? '').toString(),
        }
    };

    /// -----------------------------------------------------------------------
    /// Normalizar informações do navio
    /// -----------------------------------------------------------------------
    final finalInfo = <String, dynamic>{};

    if (infoNavio != null) {
      if (infoNavio['nacionalidadeTripulacao'] != null) {
        finalInfo['nacionalidadeTripulacao'] =
            infoNavio['nacionalidadeTripulacao'].toString().trim();
      }

      if (infoNavio['numeroCabines'] != null) {
        final n = infoNavio['numeroCabines'];
        finalInfo['numeroCabines'] =
            n is int ? n : int.tryParse(n.toString()) ?? 0;
      }

      if (infoNavio['frigobar'] != null) {
        finalInfo['frigobar'] = infoNavio['frigobar'] == true;
      }

      if (infoNavio['pia'] != null) {
        finalInfo['pia'] = infoNavio['pia'] == true;
      }
    }

    /// -----------------------------------------------------------------------
    /// Salvar avaliação na subcoleção
    /// -----------------------------------------------------------------------
    await shipRef.collection('avaliacoes').add({
      'usuarioId': userId,
      'nomeGuerra': callSign,

      /// Data informada pelo usuário (quando desembarcou)
      'dataDesembarque': Timestamp.fromDate(dataDesembarque),

      /// Timestamp oficial da criação da avaliação (servidor)
      'createdAt': FieldValue.serverTimestamp(),

      'tipoCabine': tipoCabine,
      'observacaoGeral': observacaoGeral,
      'infoNavio': finalInfo,
      'itens': normalizedItems,
    });

    /// Atualiza informações consolidadas do navio (merge)
    if (finalInfo.isNotEmpty) {
      await shipRef.set(
        {'info': finalInfo},
        SetOptions(merge: true),
      );
    }

    /// Recalcula médias agregadas do navio
    await _updateAverages(shipRef);
  }

  /// --------------------------------------------------------------------------
  /// Recalcula médias agregadas do navio
  /// --------------------------------------------------------------------------
  /// Calcula média de cada critério baseado em todas as avaliações existentes.
  ///
  /// Lógica:
  ///   1. Busca todas as avaliações do navio
  ///   2. Soma notas por critério
  ///   3. Calcula média (total / quantidade)
  ///   4. Salva no documento principal do navio
  ///
  /// Observações:
  ///   • Médias são salvas como String com 1 casa decimal
  ///   • Chaves são normalizadas via [_averageKey]
  ///   • Ignora avaliações sem notas
  Future<void> _updateAverages(
    DocumentReference<Map<String, dynamic>> shipRef,
  ) async {
    final snapshot = await shipRef.collection('avaliacoes').get();
    if (snapshot.docs.isEmpty) return;

    /// Acumuladores de soma e contagem por critério
    final total = {for (final i in _ratingCriteria) i: 0.0};
    final count = {for (final i in _ratingCriteria) i: 0};

    /// Percorre todas as avaliações somando notas
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final items = data['itens'] as Map?;
      if (items == null) continue;

      for (final item in _ratingCriteria) {
        final v = items[item];
        if (v is Map) {
          final rating = _toDouble(v['nota']);
          if (rating > 0) {
            total[item] = total[item]! + rating;
            count[item] = count[item]! + 1;
          }
        }
      }
    }

    /// Calcula médias finais
    final averages = <String, String>{};

    for (final item in _ratingCriteria) {
      if (count[item]! > 0) {
        averages[_averageKey(item)] =
            (total[item]! / count[item]!).toStringAsFixed(1);
      }
    }

    /// Atualiza documento do navio
    await shipRef.update({'medias': averages});
  }

  /// --------------------------------------------------------------------------
  /// Helpers privados
  /// --------------------------------------------------------------------------

  /// Converte valor dinâmico para double
  /// Aceita: int, double, String (com vírgula ou ponto)
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }

  /// Mapeia nome completo do critério para chave curta usada em 'medias'
  /// ⚠️ NÃO alterar sem migrar dados existentes
  String _averageKey(String item) {
    switch (item) {
      case 'Dispositivo de Embarque/Desembarque':
        return 'dispositivo';
      case 'Temperatura da Cabine':
        return 'temp_cabine';
      case 'Limpeza da Cabine':
        return 'limpeza_cabine';
      case 'Passadiço – Equipamentos':
        return 'passadico_equip';
      case 'Passadiço – Temperatura':
        return 'passadico_temp';
      case 'Comida':
        return 'comida';
      case 'Relacionamento com comandante/tripulação':
        return 'relacionamento';
      default:
        return item.toLowerCase();
    }
  }
}
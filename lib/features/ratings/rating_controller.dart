import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ----------------------------------------------------------------------------
/// RatingController
/// ----------------------------------------------------------------------------
/// Camada de controle responsável por operações relacionadas a:
///
///  • Cadastro de novos navios.
///  • Atualização de navios existentes.
///  • Registro de avaliações.
///  • Cálculo e atualização das médias.
///  • Consulta de navios existentes.
///
/// A responsabilidade desta classe é intermediar:
///  - Fluxo da AddRatingPage
///  - Firestore
///  - Autenticação do usuário
///
/// Observações importantes:
///  - Cada navio é armazenado em `navios/{imo}`.
///  - Avaliações são salvas em `navios/{imo}/avaliacoes`.
///  - O campo `medias` é recalculado a cada nova avaliação.
///  - O IMO é tratado como identificador primário, mas pode ser preenchido
///    posteriormente caso o navio tenha sido criado sem ele inicialmente.
/// ----------------------------------------------------------------------------
class RatingController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// --------------------------------------------------------------------------
  /// Retorna apenas a lista de nomes de navios cadastrados.
  /// Utilizado para autocomplete.
  /// --------------------------------------------------------------------------
  Future<List<String>> carregarNavios() async {
    final snapshot = await _firestore.collection('navios').get();
    return snapshot.docs.map((e) => e['nome'].toString()).toList();
  }

  /// --------------------------------------------------------------------------
  /// Verifica se um navio com o nome informado já existe.
  ///
  /// Retorna:
  ///  - Map<String, dynamic> com os dados se encontrado
  ///  - null caso contrário
  ///
  /// Isso permite:
  ///  • preencher automaticamente campos
  ///  • bloquear campos já definidos
  /// --------------------------------------------------------------------------
  Future<Map<String, dynamic>?> verificarNavioExistente(String nome) async {
    final query = await _firestore
        .collection('navios')
        .where('nome', isEqualTo: nome)
        .get();

    if (query.docs.isEmpty) return null;

    return query.docs.first.data();
  }

  /// --------------------------------------------------------------------------
  /// Cadastra ou atualiza um navio e registra uma avaliação.
  ///
  /// Regra de negócio:
  ///  1) Se o navio já existe:
  ///      - IMOs não são sobrescritos, mas podem ser definidos se estavam vazios.
  ///      - Apenas campos editáveis: tripulação e cabines.
  ///  2) Se não existe:
  ///      - Cria documento novo.
  ///      - Se não houver IMO inicial → salva como null.
  ///
  /// Em seguida:
  ///  - Recupera o nome de guerra do prático logado.
  ///  - Registra avaliação em subcoleção.
  ///  - Recalcula médias agregadas.
  ///
  /// Autorização:
  ///  - Usuário deve estar autenticado (uid requerido)
  /// --------------------------------------------------------------------------
  Future<void> salvarAvaliacao({
    required String nomeNavio,
    required String imoInicial,
    required int notaCamarote,
    required int notaLimpeza,
    required int notaAr,
    required int notaComida,
    required String frigobar,
    required String pia,
    required String tripulacao,
    required int cabines,
  }) async {
    final usuarioId = _auth.currentUser?.uid;
    if (usuarioId == null) {
      throw Exception('Usuário não autenticado');
    }

    final naviosRef = _firestore.collection('navios');

    /// Busca pelo nome para identificar navio pré-existente
    final query = await naviosRef.where('nome', isEqualTo: nomeNavio).get();

    late DocumentReference navioRef;
    late String imo;

    if (query.docs.isNotEmpty) {
      // ----------------------------------------------------------------------
      // NAVIO EXISTENTE
      // ----------------------------------------------------------------------
      final doc = query.docs.first;

      imo = doc['imo'] ?? '';

      // Caso o navio já exista mas ainda sem IMO e o prático informar agora
      if (imo.isEmpty && imoInicial.isNotEmpty) {
        imo = imoInicial;
        await doc.reference.update({'imo': imo});
      }

      // Se o IMO existir, usa o IMO como ID do documento
      navioRef = naviosRef.doc(imo.isEmpty ? doc.id : imo);

      // Atualiza apenas os campos que fazem sentido para edição contínua
      await navioRef.update({
        'tripulacao': tripulacao,
        'cabines': cabines,
      });

    } else {
      // ----------------------------------------------------------------------
      // NOVO NAVIO
      // ----------------------------------------------------------------------
      imo = imoInicial.isNotEmpty ? imoInicial : '';

      // Se o IMO existe → usa como ID do doc
      // Caso contrário → doc() gera ID automático
      navioRef = imo.isNotEmpty ? naviosRef.doc(imo) : naviosRef.doc();

      await navioRef.set({
        'nome': nomeNavio,
        'imo': imo.isEmpty ? null : imo,
        'frigobar': frigobar,
        'pia': pia,
        'tripulacao': tripulacao,
        'cabines': cabines,
        'medias': {},
      });
    }

    // ------------------------------------------------------------------------
    // IDENTIFICAÇÃO DO AVALIADOR
    // ------------------------------------------------------------------------
    final userSnapshot =
        await _firestore.collection('usuarios').doc(usuarioId).get();

    final nomeGuerra = userSnapshot.data()?['nomeGuerra'] ?? 'Prático';

    // ------------------------------------------------------------------------
    // SALVAR AVALIAÇÃO EM SUBCOLEÇÃO
    // ------------------------------------------------------------------------
    await navioRef.collection('avaliacoes').add({
      'usuarioId': usuarioId,
      'nomeGuerra': nomeGuerra,
      'notaCamarote': notaCamarote,
      'notaLimpeza': notaLimpeza,
      'notaAr': notaAr,
      'notaComida': notaComida,
      'data': Timestamp.now(),
    });

    // ------------------------------------------------------------------------
    // REATUALIZAR MÉDIAS GERAIS
    // ------------------------------------------------------------------------
    await _atualizarMedias(navioRef);
  }

  /// --------------------------------------------------------------------------
  /// Recalcula médias da subcoleção `avaliacoes` e atualiza o documento principal
  /// em `navios/{id}`.
  ///
  /// As médias são armazenadas como string formatada com 1 casa decimal.
  /// Isso facilita exibição e leitura rápida na UI.
  /// --------------------------------------------------------------------------
  Future<void> _atualizarMedias(DocumentReference navioRef) async {
    final snapshot = await navioRef.collection('avaliacoes').get();
    if (snapshot.docs.isEmpty) return;

    double totalCamarote = 0;
    double totalLimpeza = 0;
    double totalAr = 0;
    double totalComida = 0;

    /// Itera sobre cada avaliação acumulando valores
    for (var doc in snapshot.docs) {
      final data = doc.data();
      totalCamarote += (data['notaCamarote'] ?? 0).toDouble();
      totalLimpeza += (data['notaLimpeza'] ?? 0).toDouble();
      totalAr += (data['notaAr'] ?? 0).toDouble();
      totalComida += (data['notaComida'] ?? 0).toDouble();
    }

    final count = snapshot.docs.length;

    /// Atualiza médias agregadas
    await navioRef.update({
      'medias': {
        'camarote': (totalCamarote / count).toStringAsFixed(1),
        'limpeza': (totalLimpeza / count).toStringAsFixed(1),
        'ar': (totalAr / count).toStringAsFixed(1),
        'comida': (totalComida / count).toStringAsFixed(1),
      }
    });
  }
}

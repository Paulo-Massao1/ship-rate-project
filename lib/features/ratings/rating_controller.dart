import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ORDEM OFICIAL DOS ITENS
  static const List<String> _itensAvaliacao = [
    'Dispositivo de Embarque/Desembarque',
    'Temperatura da Cabine',
    'Limpeza da Cabine',
    'Passadiço – Equipamentos',
    'Passadiço – Temperatura',
    'Comida',
    'Relacionamento com comandante/tripulação',
  ];

  /// --------------------------------------------------------------------------
  /// Lista de navios (autocomplete / busca)
  /// --------------------------------------------------------------------------
  Future<List<String>> carregarNavios() async {
    final snapshot = await _firestore.collection('navios').get();

    final nomes = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final nome = (data['nome'] ?? '').toString().trim();
      final imo = (data['imo'] ?? '').toString().trim();

      if (nome.isNotEmpty) nomes.add(nome);
      if (imo.isNotEmpty) nomes.add(imo);
    }

    return nomes.toList();
  }

  /// --------------------------------------------------------------------------
  /// Salvar avaliação
  /// --------------------------------------------------------------------------
  Future<void> salvarAvaliacao({
    required String nomeNavio,
    required String imoInicial,
    required DateTime dataDesembarque,
    required String tipoCabine,
    required String observacaoGeral,
    required Map<String, Map<String, dynamic>> itens,
    Map<String, dynamic>? infoNavio,
  }) async {
    final usuarioId = _auth.currentUser?.uid;
    if (usuarioId == null) {
      throw Exception('Usuário não autenticado');
    }

    final naviosRef = _firestore.collection('navios');

    final nomeNormalizado = nomeNavio.trim();
    final imoNormalizado = imoInicial.trim();

    if (nomeNormalizado.isEmpty && imoNormalizado.isEmpty) {
      throw Exception('Nome ou IMO do navio é obrigatório');
    }

    /// ----------------------------------------------------------
    /// 🔍 BUSCA DO NAVIO (IMO > NOME)
    /// ----------------------------------------------------------
    QuerySnapshot<Map<String, dynamic>> query;

    if (imoNormalizado.isNotEmpty) {
      query = await naviosRef
          .where('imo', isEqualTo: imoNormalizado)
          .limit(1)
          .get();
    } else {
      query = await naviosRef
          .where('nome', isEqualTo: nomeNormalizado)
          .limit(1)
          .get();
    }

    late DocumentReference<Map<String, dynamic>> navioRef;

    if (query.docs.isNotEmpty) {
      navioRef = query.docs.first.reference;
    } else {
      navioRef = naviosRef.doc();

      await navioRef.set({
        'nome': nomeNormalizado,
        'imo': imoNormalizado.isNotEmpty ? imoNormalizado : null,
        'medias': {},
        'info': {},
      });
    }

    /// ----------------------------------------------------------
    /// Nome de guerra
    /// ----------------------------------------------------------
    final userSnapshot =
        await _firestore.collection('usuarios').doc(usuarioId).get();
    final nomeGuerra = userSnapshot.data()?['nomeGuerra'] ?? 'Prático';

    /// ----------------------------------------------------------
    /// Normalizar itens (compatível com versões antigas)
    /// ----------------------------------------------------------
    final itensNormalizados = {
      for (final item in _itensAvaliacao)
        item: {
          'nota': _toDouble(itens[item]?['nota']),
          'observacao': (itens[item]?['observacao'] ?? '').toString(),
        }
    };

    /// ----------------------------------------------------------
    /// Normalizar infoNavio
    /// ----------------------------------------------------------
    final infoFinal = <String, dynamic>{};

    if (infoNavio != null) {
      if (infoNavio['nacionalidadeTripulacao'] != null) {
        infoFinal['nacionalidadeTripulacao'] =
            infoNavio['nacionalidadeTripulacao'].toString().trim();
      }

      if (infoNavio['numeroCabines'] != null) {
        final n = infoNavio['numeroCabines'];
        infoFinal['numeroCabines'] =
            n is int ? n : int.tryParse(n.toString()) ?? 0;
      }

      if (infoNavio['frigobar'] != null) {
        infoFinal['frigobar'] = infoNavio['frigobar'] == true;
      }

      if (infoNavio['pia'] != null) {
        infoFinal['pia'] = infoNavio['pia'] == true;
      }
    }

    /// ----------------------------------------------------------
    /// Salvar avaliação
    /// ----------------------------------------------------------
    await navioRef.collection('avaliacoes').add({
      'usuarioId': usuarioId,
      'nomeGuerra': nomeGuerra,
      'dataDesembarque': Timestamp.fromDate(dataDesembarque),
      'tipoCabine': tipoCabine,
      'observacaoGeral': observacaoGeral,
      'infoNavio': infoFinal,
      'itens': itensNormalizados,
      'data': Timestamp.now(),
    });

    /// Atualizar info resumida do navio
    if (infoFinal.isNotEmpty) {
      await navioRef.set(
        {'info': infoFinal},
        SetOptions(merge: true),
      );
    }

    await _atualizarMedias(navioRef);
  }

  /// --------------------------------------------------------------------------
  /// Recalcular médias
  /// --------------------------------------------------------------------------
  Future<void> _atualizarMedias(
      DocumentReference<Map<String, dynamic>> navioRef) async {
    final snapshot = await navioRef.collection('avaliacoes').get();
    if (snapshot.docs.isEmpty) return;

    final total = {for (final i in _itensAvaliacao) i: 0.0};
    final count = {for (final i in _itensAvaliacao) i: 0};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final itens = data['itens'] as Map?;
      if (itens == null) continue;

      for (final item in _itensAvaliacao) {
        final v = itens[item];
        if (v is Map) {
          final nota = _toDouble(v['nota']);
          if (nota > 0) {
            total[item] = total[item]! + nota;
            count[item] = count[item]! + 1;
          }
        }
      }
    }

    final medias = <String, String>{};
    for (final item in _itensAvaliacao) {
      if (count[item]! > 0) {
        medias[_mediaKey(item)] =
            (total[item]! / count[item]!).toStringAsFixed(1);
      }
    }

    await navioRef.update({'medias': medias});
  }

  /// --------------------------------------------------------------------------
  /// Helpers
  /// --------------------------------------------------------------------------
  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
    return 0.0;
  }

  String _mediaKey(String item) {
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

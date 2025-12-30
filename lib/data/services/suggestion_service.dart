import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Serviço responsável pelo envio e registro de sugestões no Firestore.
///
/// Função e objetivo:
/// -------------------
/// Este serviço abstrai o processo de salvar sugestões dos usuários
/// em uma coleção dedicada no Firestore chamada `sugestoes`.
///
/// Ele permite que o app:
///   • colete feedback de pilotos/usuários
///   • registre melhorias solicitadas
///   • tenha histórico de pedidos
///   • consulte posteriormente no painel Firebase
///
/// Não existe resposta por e-mail aqui — o envio é apenas persistido
/// para posterior leitura e análise.
///
/// Modelo salvo no Firestore:
/// ```json
/// {
///   "email": "usuario@exemplo.com",
///   "titulo": "Melhorar UI",
///   "mensagem": "A busca poderia ser mais rápida",
///   "createdAt": <timestamp>
/// }
/// ```
///
/// Detalhes técnicos:
/// ------------------
/// • Usa `FieldValue.serverTimestamp()` para garantir horário oficial.
/// • Em caso de erro:
///   - não lança exceção
///   - retorna `false`
///   - loga no console (útil para debug)
///
/// Este design simplifica o uso no front-end ― permitindo:
/// ```dart
/// final ok = await SugestaoService.enviar(...);
/// if (ok) showSuccess();
/// else showError();
/// ```
class SuggestionService {
  /// Nome da coleção no Firestore
  /// Mantido como 'sugestoes' para compatibilidade com dados existentes
  static const String _collectionName = 'sugestoes';

  static Future<bool> send({
    required String email,
    required String title,
    required String message,
  }) async {
    try {
      await FirebaseFirestore.instance.collection(_collectionName).add({
        'email': email,
        'title': title,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (error) {
      debugPrint('❌ Erro ao salvar sugestão: $error');
      return false;
    }
  }
}

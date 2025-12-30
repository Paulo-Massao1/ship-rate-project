import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:universal_html/html.dart' as html;

/// ============================================================================
/// VERSION SERVICE
/// ============================================================================
/// Serviço responsável por verificar versão do app e gerenciar atualizações.
/// 
/// Funcionalidades:
/// ----------------
/// • Compara versão local (localStorage) com versão remota (Firestore)
/// • Determina se deve exibir banner de atualização
/// • Registra que usuário já viu o banner (evita repetição)
/// • Atualiza versão local após usuário reabrir o app
///
/// Fluxo de Atualização:
/// ---------------------
/// 1. Usuário abre app
/// 2. Service busca versão remota no Firestore
/// 3. Compara com versão salva no localStorage
/// 4. Se versão mudou E ainda não viu banner → mostra banner
/// 5. Usuário clica OK → marca como visto
/// 6. Usuário fecha e reabre → atualiza versão local
///
/// Armazenamento:
/// --------------
/// • localStorage['app_local_version']: Versão que está rodando
/// • localStorage['seen_banner_version']: Versão do banner que já viu
/// • Firestore config/app_version: Versão atual (fonte de verdade)
///
class VersionService {
  /// Chave para versão local salva no localStorage
  static const String _localVersionKey = 'app_local_version';
  
  /// Chave para versão do banner que já foi visto
  static const String _seenVersionKey = 'seen_banner_version';

  /// --------------------------------------------------------------------------
  /// Salva valor no localStorage do navegador
  /// --------------------------------------------------------------------------
  static void _setLocal(String key, String value) {
    html.window.localStorage[key] = value;
  }

  /// --------------------------------------------------------------------------
  /// Busca valor do localStorage do navegador
  /// --------------------------------------------------------------------------
  static String? _getLocal(String key) {
    return html.window.localStorage[key];
  }

  /// --------------------------------------------------------------------------
  /// Verifica se deve mostrar banner de atualização
  /// --------------------------------------------------------------------------
  /// 
  /// Retorna Map com:
  ///   • shouldShow (bool): Se deve exibir banner
  ///   • message (String?): Mensagem personalizada do Firestore
  ///   • version (String?): Versão remota
  ///
  /// Lógica de Decisão:
  ///   • Primeira vez → Salva versão e não mostra banner
  ///   • Versões iguais → Não mostra banner
  ///   • Já viu banner desta versão → Atualiza local e não mostra
  ///   • Versão diferente e não viu → Mostra banner!
  ///
  static Future<Map<String, dynamic>> shouldShowUpdateBanner() async {
    try {
      // Busca documento de versão no Firestore
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('app_version')
          .get();

      // Valida existência do documento
      if (!doc.exists) {
        return {'shouldShow': false, 'message': null};
      }

      final data = doc.data()!;
      final remoteVersion = data['version'] as String?;
      
      // Valida versão remota
      if (remoteVersion == null) {
        return {'shouldShow': false, 'message': null};
      }

      // Mensagem personalizada ou padrão
      final message = data['message'] as String? ?? 
          'Nova atualização disponível. Por favor, feche e reabra o app para aplicar as melhorias.';

      // Busca versões salvas localmente
      final localVersion = _getLocal(_localVersionKey);
      final seenVersion = _getLocal(_seenVersionKey);

      // -----------------------------------------------------------------------
      // PRIMEIRA VEZ: Salva versão atual e não mostra banner
      // -----------------------------------------------------------------------
      if (localVersion == null) {
        _setLocal(_localVersionKey, remoteVersion);
        return {'shouldShow': false, 'message': null};
      }

      // -----------------------------------------------------------------------
      // VERSÕES IGUAIS: Não há atualização
      // -----------------------------------------------------------------------
      if (localVersion == remoteVersion) {
        return {'shouldShow': false, 'message': null};
      }

      // -----------------------------------------------------------------------
      // JÁ VIU BANNER: Atualiza versão local (usuário já reabriu)
      // -----------------------------------------------------------------------
      if (seenVersion == remoteVersion) {
        _setLocal(_localVersionKey, remoteVersion);
        return {'shouldShow': false, 'message': null};
      }

      // -----------------------------------------------------------------------
      // NOVA VERSÃO DETECTADA: Mostra banner!
      // -----------------------------------------------------------------------
      return {
        'shouldShow': true,
        'message': message,
        'version': remoteVersion,
      };
    } catch (error) {
      // Em caso de erro, não mostra banner (fail-safe)
      return {'shouldShow': false, 'message': null};
    }
  }

  /// --------------------------------------------------------------------------
  /// Marca que usuário viu o banner desta versão
  /// --------------------------------------------------------------------------
  /// 
  /// Chamado quando usuário clica em "OK" no banner.
  /// Salva qual versão o usuário já foi notificado para não mostrar novamente.
  ///
  static Future<void> markBannerAsSeen() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('app_version')
          .get();
      
      if (doc.exists) {
        final remoteVersion = doc.data()?['version'] as String?;
        
        if (remoteVersion != null) {
          _setLocal(_seenVersionKey, remoteVersion);
        }
      }
    } catch (error) {
      // Silenciosamente ignora erro (não crítico)
    }
  }

  /// --------------------------------------------------------------------------
  /// Limpa dados de versionamento (útil para testes)
  /// --------------------------------------------------------------------------
  /// 
  /// Remove todas as informações de versão salvas localmente.
  /// Usado apenas em desenvolvimento/debug.
  ///
  static void clearVersionData() {
    html.window.localStorage.remove(_localVersionKey);
    html.window.localStorage.remove(_seenVersionKey);
  }
}
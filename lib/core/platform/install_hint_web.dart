// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'install_hint_service.dart';

/// Implementação Web do serviço de exibição de aviso de instalação.
///
/// Esta classe utiliza recursos do `dart:html`, portanto
/// é destinada exclusivamente a rodar em ambiente Web.
/// Por isso usamos:
///   • ignore: avoid_web_libraries_in_flutter
/// 
/// O objetivo é detectar se o PWA está sendo executado:
///   • como PWA instalado (tela cheia / standalone)
///   • ou dentro do navegador comum.
///
/// A detecção ocorre via `MediaQuery` Web API:
///
///   `(display-mode: standalone)`
///
/// Retornos:
///   • `false` → já instalado como PWA → não mostrar aviso
///   • `true` → rodando no navegador → sugerir instalação
///
/// Esta implementação complementa a versão Mobile, mantendo
/// o comportamento multiplataforma via interface `InstallHintService`.
class InstallHintWebService implements InstallHintService {
  @override
  bool shouldShowInstallHint() {
    // Verifica o modo de exibição:
    // standalone → PWA instalado
    // browser → não instalado
    final mq = html.window.matchMedia('(display-mode: standalone)');

    // Caso não esteja no modo standalone, sugerimos exibir o banner.
    return !mq.matches;
  }
}

/// Factory global
///
/// Em ambiente Web, esta função retorna `InstallHintWebService`.
/// No ambiente Mobile, outra implementação será usada.
///
/// Ela permite que a UI utilize:
///
/// ```dart
/// final service = getInstallHintService();
/// if (service.shouldShowInstallHint()) {
///   showBanner();
/// }
/// ```
InstallHintService getInstallHintService() {
  return InstallHintWebService();
}

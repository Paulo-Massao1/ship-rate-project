import '../../core/platform/install_hint.dart';

/// Controller responsável por regras de negócio da tela principal (`MainScreen`).
///
/// Objetivos principais:
/// ---------------------
/// • Abstrair lógica referente à verificação se o app precisa sugerir instalação
///   quando rodando como PWA no navegador.
///
/// • Futuramente centralizar ações do usuário na Home, como:
///     – logout
///     – verificação de versões
///     – carregamento inicial
///
/// Sobre o install hint:
/// ---------------------
/// O método [shouldShowInstallHint] delega para a implementação correta
/// de acordo com a plataforma.
///
/// No mobile: retorna sempre `false` (pois apps mobile já são instalados).
/// No web: checa via `matchMedia('(display-mode: standalone)')`
/// para detectar se o usuário está rodando o PWA como instalado ou não.
///
/// `getInstallHintService()` utiliza conditional import:
///     - install_hint_mobile.dart → para Android/iOS
///     - install_hint_web.dart → para PWA, com acesso ao `dart:html`
class MainScreenController {
  /// Serviço responsável pela lógica de detecção de instalação PWA.
  final _installHintService = getInstallHintService();

  /// Informa se o app deve exibir uma sugestão (hint) para instalação PWA.
  ///
  /// Em navegadores desktop/mobile:
  ///   - retorna `true` caso o app esteja rodando no modo "browser"
  ///   - retorna `false` quando já está em modo "standalone" (PWA instalado)
  bool shouldShowInstallHint() {
    return _installHintService.shouldShowInstallHint();
  }

  /// Método para logout (atualmente não implementado).
  ///
  /// Observação:
  /// -----------
  /// - A implementação padrão do logout fica geralmente no AuthController.
  /// - Aqui existe o método para permitir que a Home execute logout
  ///   caso a UI deseje delegar a responsabilidade ao controller.
  ///
  /// Exemplo futuro:
  /// ```dart
  /// await FirebaseAuth.instance.signOut();
  /// ```
  Future<void> logout() async {
    // FirebaseAuth.instance.signOut();
  }
}

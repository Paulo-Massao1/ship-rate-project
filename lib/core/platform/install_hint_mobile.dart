import 'install_hint_service.dart';

/// Implementação específica para ambiente mobile.
///
/// Este serviço faz parte da lógica de detecção de instalação PWA.
/// Em plataformas Web, o app pode exibir um banner orientando o usuário
/// a "Adicionar à tela inicial".
///
/// Já em dispositivos mobile (Android/iOS rodando como app Flutter ou
/// instalado como PWA), essa dica não é necessária.
///
/// Portanto:
///   • No Mobile → nunca exibimos o aviso.
///   • No Web → outra implementação cuidará disso.
///
/// Esta classe implementa a interface `InstallHintService`
/// garantindo padronização entre plataformas.
class InstallHintMobileService implements InstallHintService {
  
  /// Retorna `false` porque em dispositivos móveis
  /// não queremos exibir dica de instalação da PWA.
  ///
  /// Caso o app esteja empacotado como nativo (APK, IPA)
  /// ou já instalado via PWA, esse aviso seria redundante.
  @override
  bool shouldShowInstallHint() {
    return false;
  }
}

/// Factory para retornar a implementação correta.
/// 
/// Na plataforma mobile, sempre retornamos a implementação
/// `InstallHintMobileService`.
///
/// No Web (em outro arquivo), essa função será sobrescrita via `conditional import`, 
/// permitindo retornar a implementação Web que mostra o banner.
///
/// Exemplo:
///   getInstallHintService().shouldShowInstallHint();
InstallHintService getInstallHintService() {
  return InstallHintMobileService();
}

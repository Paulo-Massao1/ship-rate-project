/// Define a interface para serviços responsáveis por determinar
/// se o aplicativo deve exibir ou não uma dica de instalação.
///
/// Esta abstração é usada para suportar múltiplas plataformas.
///
/// Exemplos de implementações:
///   • Web: pode retornar `true` para sugerir instalação como PWA
///   • Mobile (Android/iOS): normalmente retorna `false`
///
/// Com interface separada, garantimos:
///   • desacoplamento entre UI e lógica de plataforma
///   • possibilidade de usar `conditional import`
///   • substituição de comportamento sem alterar a UI
///
/// Uso típico:
/// ```dart
/// final hintService = getInstallHintService();
/// if (hintService.shouldShowInstallHint()) {
///   // mostrar banner de instalação
/// }
/// ```
abstract class InstallHintService {
  
  /// Método que sinaliza se o app deve exibir um aviso
  /// sugerindo instalação (ex: "Adicionar à tela inicial").
  ///
  /// Retorno:
  ///   • `true` → sugere exibir aviso
  ///   • `false` → não exibir aviso
  bool shouldShowInstallHint();
}

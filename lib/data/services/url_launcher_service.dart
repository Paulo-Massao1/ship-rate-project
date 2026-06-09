import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class UrlLauncherService {
  const UrlLauncherService._();

  static Future<bool> openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;

    try {
      if (kIsWeb) {
        html.window.open(url, '_blank');
        return true;
      } else {
        return await url_launcher.launchUrl(
          uri,
          mode: url_launcher.LaunchMode.externalApplication,
        );
      }
    } catch (error) {
      debugPrint('UrlLauncherService.openExternalUrl failed: $error');
      return false;
    }
  }

  static Future<bool> openWhatsAppShare(String text) {
    final url = 'https://wa.me/?text=${Uri.encodeComponent(text)}';
    debugPrint('UrlLauncherService.openWhatsAppShare URL: $url');
    return openExternalUrl(url);
  }
}

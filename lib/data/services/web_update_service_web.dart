import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

class WebUpdateService {
  const WebUpdateService._();

  static Future<void> applyUpdate() async {
    await _refreshServiceWorkers();
    await _clearAppCaches();
    _reloadWithCacheBust();
  }

  static Future<void> _refreshServiceWorkers() async {
    try {
      final registrations = await web.window.navigator.serviceWorker
          .getRegistrations()
          .toDart
          .timeout(const Duration(seconds: 3));

      for (final registration in registrations.toDart) {
        try {
          registration.waiting?.postMessage(
            <String, String>{'type': 'SKIP_WAITING'}.jsify(),
          );
          await registration.update().toDart.timeout(
            const Duration(seconds: 2),
          );
        } catch (_) {
          // The cache clear and reload below still move the web app forward.
        }

        try {
          await registration.unregister().toDart.timeout(
            const Duration(seconds: 2),
          );
        } catch (_) {
          // A failed unregister should not block the refresh attempt.
        }
      }
    } catch (_) {
      // Some browsers restrict service worker access; reload still helps.
    }
  }

  static Future<void> _clearAppCaches() async {
    try {
      final caches = web.window.caches;
      final cacheNames = await caches.keys().toDart.timeout(
        const Duration(seconds: 3),
      );
      await Future.wait(
        cacheNames.toDart.map(
          (cacheName) => caches.delete(cacheName.toDart).toDart,
        ),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Cache APIs can be unavailable in private mode or older WebViews.
    }
  }

  static void _reloadWithCacheBust() {
    final currentUri = Uri.parse(web.window.location.href);
    final queryParameters = Map<String, String>.from(
      currentUri.queryParameters,
    )..['_sr_update'] = DateTime.now().millisecondsSinceEpoch.toString();

    final targetUri = currentUri.replace(queryParameters: queryParameters);
    web.window.location.replace(targetUri.toString());
  }
}

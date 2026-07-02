import 'dart:async';
import 'dart:html' as html;

class WebUpdateService {
  const WebUpdateService._();

  static Future<void> applyUpdate() async {
    await _refreshServiceWorkers();
    await _clearAppCaches();
    _reloadWithCacheBust();
  }

  static Future<void> _refreshServiceWorkers() async {
    final serviceWorker = html.window.navigator.serviceWorker;
    if (serviceWorker == null) return;

    try {
      final registrations = await serviceWorker
          .getRegistrations()
          .timeout(const Duration(seconds: 3));

      for (final registration in registrations) {
        if (registration is! html.ServiceWorkerRegistration) continue;

        try {
          registration.waiting?.postMessage({'type': 'SKIP_WAITING'});
          await registration.update().timeout(const Duration(seconds: 2));
        } catch (_) {
          // The cache clear and reload below still move the web app forward.
        }

        try {
          await registration.unregister().timeout(const Duration(seconds: 2));
        } catch (_) {
          // A failed unregister should not block the refresh attempt.
        }
      }
    } catch (_) {
      // Some browsers restrict service worker access; reload still helps.
    }
  }

  static Future<void> _clearAppCaches() async {
    final caches = html.window.caches;
    if (caches == null) return;

    try {
      final cacheNames = await caches.keys().timeout(const Duration(seconds: 3));
      await Future.wait(
        cacheNames
            .whereType<String>()
            .map((cacheName) => caches.delete(cacheName)),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Cache APIs can be unavailable in private mode or older WebViews.
    }
  }

  static void _reloadWithCacheBust() {
    final currentUri = Uri.parse(html.window.location.href);
    final queryParameters = Map<String, String>.from(
      currentUri.queryParameters,
    )..['_sr_update'] = DateTime.now().millisecondsSinceEpoch.toString();

    final targetUri = currentUri.replace(queryParameters: queryParameters);
    html.window.location.replace(targetUri.toString());
  }
}

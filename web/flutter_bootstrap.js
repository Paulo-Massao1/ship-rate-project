{{flutter_js}}
{{flutter_build_config}}

(async function () {
  if (window.shipRateFirebaseSdkReady) {
    try {
      await window.shipRateFirebaseSdkReady;
    } catch (error) {
      console.warn('Firebase SDK preload failed before Flutter bootstrap', error);
    }
  }

  _flutter.loader.load();
})();

importScripts('https://www.gstatic.com/firebasejs/11.9.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.9.1/firebase-messaging-compat.js');
firebase.initializeApp({
  apiKey: 'AIzaSyCFFFbTHNPMA9t1ABrC_uk92ym8SEKSSHI',
  appId: '1:718297005782:web:1a2e4f254323a13c685377',
  messagingSenderId: '718297005782',
  projectId: 'shiprate-daf18',
  authDomain: 'shiprate-daf18.firebaseapp.com',
  storageBucket: 'shiprate-daf18.firebasestorage.app',
  measurementId: 'G-ZP68WL1MM3',
});
const messaging = firebase.messaging();
self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({type: 'window', includeUncontrolled: true})
      .then(function(clientList) {
        for (var i = 0; i < clientList.length; i++) {
          if (clientList[i].url.includes('shiprate') && 'focus' in clientList[i]) {
            return clientList[i].focus();
          }
        }
        return clients.openWindow('https://shiprate-daf18.web.app');
      })
  );
});

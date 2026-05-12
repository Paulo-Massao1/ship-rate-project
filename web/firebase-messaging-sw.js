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
messaging.onBackgroundMessage((payload) => {
  const title = payload.notification.title;
  const options = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png',
  };
  return self.registration.showNotification(title, options);
});

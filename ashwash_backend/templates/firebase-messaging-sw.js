importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Real Firebase Config
const firebaseConfig = {
    apiKey: "AIzaSyCKNb5xzn07zwOnz8i0M3llDEOOrOqJZm4",
    authDomain: "ashwash-b0441.firebaseapp.com",
    projectId: "ashwash-b0441",
    storageBucket: "ashwash-b0441.firebasestorage.app",
    messagingSenderId: "498385268612",
    appId: "1:498385268612:web:ecf2c65fb168fbd0a5f7d1"
};

try {
    firebase.initializeApp(firebaseConfig);
    const messaging = firebase.messaging();

    messaging.onBackgroundMessage((payload) => {
        console.log('[firebase-messaging-sw.js] Received background message ', payload);
        const notificationTitle = payload.notification.title;
        const notificationOptions = {
            body: payload.notification.body,
            icon: '/static/images/logo.png' // Use a local logo if possible
        };

        self.registration.showNotification(notificationTitle, notificationOptions);
    });
} catch (e) {
    console.error("Firebase SW: Could not initialize", e);
}

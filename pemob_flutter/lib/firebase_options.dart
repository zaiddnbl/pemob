import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBYIhDRUf5gRIf5FjqWp4lYJWLmePVBhCA',
    authDomain: 'sipesel-d9e8b.firebaseapp.com',
    projectId: 'sipesel-d9e8b',
    storageBucket: 'sipesel-d9e8b.firebasestorage.app',
    messagingSenderId: '815037750503',
    appId: '1:815037750503:web:9c637e9c18401870781642',
    measurementId: 'G-WGDR57K4N9',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBYIhDRUf5gRIf5FjqWp4lYJWLmePVBhCA',
    authDomain: 'sipesel-d9e8b.firebaseapp.com',
    projectId: 'sipesel-d9e8b',
    storageBucket: 'sipesel-d9e8b.firebasestorage.app',
    messagingSenderId: '815037750503',
    appId: '1:815037750503:web:9c637e9c18401870781642',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBYIhDRUf5gRIf5FjqWp4lYJWLmePVBhCA',
    authDomain: 'sipesel-d9e8b.firebaseapp.com',
    projectId: 'sipesel-d9e8b',
    storageBucket: 'sipesel-d9e8b.firebasestorage.app',
    messagingSenderId: '815037750503',
    appId: '1:815037750503:web:9c637e9c18401870781642',
    measurementId: 'G-WGDR57K4N9',
  );
}

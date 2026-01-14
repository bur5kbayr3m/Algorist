import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Dummy Firebase Options - Replace with real credentials from Firebase Console
/// https://console.firebase.google.com
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Dummy credentials - Replace with real Firebase project credentials
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDummyApiKeyForWebDevelopment',
    appId: '1:123456789012:web:abcdef0123456789',
    messagingSenderId: '123456789012',
    projectId: 'algorist-dummy',
    authDomain: 'algorist-dummy.firebaseapp.com',
    databaseURL: 'https://algorist-dummy.firebaseio.com',
    storageBucket: 'algorist-dummy.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDummyApiKeyForAndroidDevelopment',
    appId: '1:123456789012:android:abcdef0123456789',
    messagingSenderId: '123456789012',
    projectId: 'algorist-dummy',
    databaseURL: 'https://algorist-dummy.firebaseio.com',
    storageBucket: 'algorist-dummy.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDummyApiKeyForIOSDevelopment',
    appId: '1:123456789012:ios:abcdef0123456789',
    messagingSenderId: '123456789012',
    projectId: 'algorist-dummy',
    databaseURL: 'https://algorist-dummy.firebaseio.com',
    storageBucket: 'algorist-dummy.appspot.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDummyApiKeyForMacOSDevelopment',
    appId: '1:123456789012:macos:abcdef0123456789',
    messagingSenderId: '123456789012',
    projectId: 'algorist-dummy',
    databaseURL: 'https://algorist-dummy.firebaseio.com',
    storageBucket: 'algorist-dummy.appspot.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDummyApiKeyForWindowsDevelopment',
    appId: '1:123456789012:windows:abcdef0123456789',
    messagingSenderId: '123456789012',
    projectId: 'algorist-dummy',
    databaseURL: 'https://algorist-dummy.firebaseio.com',
    storageBucket: 'algorist-dummy.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyDummyApiKeyForLinuxDevelopment',
    appId: '1:123456789012:linux:abcdef0123456789',
    messagingSenderId: '123456789012',
    projectId: 'algorist-dummy',
    databaseURL: 'https://algorist-dummy.firebaseio.com',
    storageBucket: 'algorist-dummy.appspot.com',
  );
}


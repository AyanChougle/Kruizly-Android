import '''package:firebase_core/firebase_core.dart''' show FirebaseOptions;
import '''package:flutter/foundation.dart'''
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Based on Kruizly production project: carrentpeweb
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
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '''AIzaSyARhtzwJV90HcdN7_szUWP34ZQ7zS2iMOw''',
    appId: '''1:903989537070:web:98402187513738b65d32bf''',
    messagingSenderId: '''903989537070''',
    projectId: '''carrentpeweb''',
    authDomain: '''carrentpeweb.firebaseapp.com''',
    storageBucket: '''carrentpeweb.firebasestorage.app''',
    measurementId: '''G-04LJBW1137''',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '''AIzaSyARhtzwJV90HcdN7_szUWP34ZQ7zS2iMOw''',
    appId: '''1:903989537070:android:98402187513738b65d32bf''',
    messagingSenderId: '''903989537070''',
    projectId: '''carrentpeweb''',
    storageBucket: '''carrentpeweb.firebasestorage.app''',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '''AIzaSyARhtzwJV90HcdN7_szUWP34ZQ7zS2iMOw''',
    appId: '''1:903989537070:ios:98402187513738b65d32bf''',
    messagingSenderId: '''903989537070''',
    projectId: '''carrentpeweb''',
    storageBucket: '''carrentpeweb.firebasestorage.app''',
    iosBundleId: '''com.Kruizly.app''',
  );
}

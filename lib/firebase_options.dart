// Automatically generated; customized for this project using the user's provided Firebase configs.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC0PH_ZMrXiAWzLAlnQ8PjSM2lWsRt9KG0',
    authDomain: 'aidsense-3dab7.firebaseapp.com',
    projectId: 'aidsense-3dab7',
    storageBucket: 'aidsense-3dab7.firebasestorage.app',
    messagingSenderId: '758673088506',
    appId: '1:758673088506:web:5f2c812fe8654596b84e43',
    measurementId: 'G-BBG12E6YW3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCVkNG8W8KMg3nxk2kIi43psMJ9rvj7SFw',
    appId: '1:758673088506:android:643fb7dce9df9259b84e43',
    messagingSenderId: '758673088506',
    projectId: 'aidsense-3dab7',
    storageBucket: 'aidsense-3dab7.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDr_6JBo7KJLxcUMLrM--ViW0Z3MPk1T48',
    appId: '1:758673088506:ios:3d5fe7fb12b81298b84e43',
    messagingSenderId: '758673088506',
    projectId: 'aidsense-3dab7',
    storageBucket: 'aidsense-3dab7.firebasestorage.app',
    iosBundleId: 'com.sparsh.aidsense',
  );
}
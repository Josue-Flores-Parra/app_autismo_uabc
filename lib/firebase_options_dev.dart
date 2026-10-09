// Configuracion del proyecto Firebase de desarrollo. Para regenerarla:
// flutterfire configure --project=appy-dev-uabc --out=lib/firebase_options_dev.dart
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// [FirebaseOptions] del proyecto de desarrollo `appy-dev-uabc`.
///
/// Conserva el nombre que genera FlutterFire para poder regenerar el archivo.
/// `lib/core/app_environment.dart` lo importa con prefijo y decide si se usan
/// estas opciones o las de produccion de `firebase_options.dart`.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAXAnIY07mYgem33IM4QuKqLTz29qQDgJM',
    appId: '1:331482779837:web:17ce891ae1be1b63e3a7d4',
    messagingSenderId: '331482779837',
    projectId: 'appy-dev-uabc',
    authDomain: 'appy-dev-uabc.firebaseapp.com',
    storageBucket: 'appy-dev-uabc.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCotD7doWepc31z0h5RI1t1rVO0CAPW3ME',
    appId: '1:331482779837:android:d60fe45645e09c71e3a7d4',
    messagingSenderId: '331482779837',
    projectId: 'appy-dev-uabc',
    storageBucket: 'appy-dev-uabc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC1tHYx2nCVNfA5ep4Q9tEP0gI2QJ00_aU',
    appId: '1:331482779837:ios:96f4c51ec9fc2245e3a7d4',
    messagingSenderId: '331482779837',
    projectId: 'appy-dev-uabc',
    storageBucket: 'appy-dev-uabc.firebasestorage.app',
    iosBundleId: 'com.appytea.appy',
  );
}

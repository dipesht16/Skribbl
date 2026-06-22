import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Generated/restored configuration options for scribble-7bcd4.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDpJjkCcO2ippZQyxxAXKqVhw2JInnTqHk',
    appId: '1:523813854180:web:9fdfbe05a397858c7bcd4c',
    messagingSenderId: '523813854180',
    projectId: 'scribble-7bcd4',
    authDomain: 'scribble-7bcd4.firebaseapp.com',
    databaseURL: 'https://scribble-7bcd4-default-rtdb.firebaseio.com/',
    storageBucket: 'scribble-7bcd4.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDpJjkCcO2ippZQyxxAXKqVhw2JInnTqHk',
    appId: '1:523813854180:android:d7386d8cae9cbc3f3705f1',
    messagingSenderId: '523813854180',
    projectId: 'scribble-7bcd4',
    databaseURL: 'https://scribble-7bcd4-default-rtdb.firebaseio.com/',
    storageBucket: 'scribble-7bcd4.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDpJjkCcO2ippZQyxxAXKqVhw2JInnTqHk',
    appId: '1:523813854180:ios:f57ad1fb64c7adbe7bcd4c',
    messagingSenderId: '523813854180',
    projectId: 'scribble-7bcd4',
    databaseURL: 'https://scribble-7bcd4-default-rtdb.firebaseio.com/',
    storageBucket: 'scribble-7bcd4.firebasestorage.app',
    iosBundleId: 'com.example.skribbleIo',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDpJjkCcO2ippZQyxxAXKqVhw2JInnTqHk',
    appId: '1:523813854180:ios:f57ad1fb64c7adbe7bcd4c',
    messagingSenderId: '523813854180',
    projectId: 'scribble-7bcd4',
    databaseURL: 'https://scribble-7bcd4-default-rtdb.firebaseio.com/',
    storageBucket: 'scribble-7bcd4.firebasestorage.app',
    iosBundleId: 'com.example.skribbleIo',
  );
}

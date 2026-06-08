import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD9dCIrsjLkmDpy-XnD_UkV_PsxmngyRz0',
    appId: '1:647299017326:ios:14d1ca48827af2e69a947f',
    messagingSenderId: '647299017326',
    projectId: 'hfaapp-947e5',
    storageBucket: 'hfaapp-947e5.firebasestorage.app',
    iosBundleId: 'com.hfa.academy',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBAqA_fgxh-X_PNxl9_gy04PssZ0NxL-Z8',
    appId: '1:647299017326:android:7d8cec07920568af9a947f',
    messagingSenderId: '647299017326',
    projectId: 'hfaapp-947e5',
    storageBucket: 'hfaapp-947e5.firebasestorage.app',
  );
}

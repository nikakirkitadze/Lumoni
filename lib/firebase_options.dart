import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Default [FirebaseOptions] for the current platform.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDh6yt1wg0GtmQkd_EqXTn5WF3k0YOIFcc',
    appId: '1:396928377391:ios:0df6a5299815aed9005cda',
    messagingSenderId: '396928377391',
    projectId: 'build-x-36c66',
    storageBucket: 'build-x-36c66.firebasestorage.app',
    iosBundleId: 'ge.grich.lumoni',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCwmeIJcyt38CsKB0Y3LFel3tq8EuOiXmg',
    appId: '1:396928377391:android:70199bee71b926f6005cda',
    messagingSenderId: '396928377391',
    projectId: 'build-x-36c66',
    storageBucket: 'build-x-36c66.firebasestorage.app',
  );
}

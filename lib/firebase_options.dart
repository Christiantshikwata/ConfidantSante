// Options Firebase générées à partir de android/app/google-services.json.
// Permet d'initialiser Firebase sans dépendre du plugin Gradle google-services.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return android;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return android; // À remplacer par les vraies options iOS si disponibles.
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD_yoWT2chpIuwvV3O8Nmxyx5HTv-pBjLA',
    appId: '1:270791856003:android:d083f92d7ef4832a4cb0b6',
    messagingSenderId: '270791856003',
    projectId: 'confidantsante',
    storageBucket: 'confidantsante.firebasestorage.app',
  );
}

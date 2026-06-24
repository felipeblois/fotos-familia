import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<void> initialize() async {
    if (!AppConfig.hasFirebaseConfig) {
      return;
    }

    if (_hasInitializedApp()) {
      return;
    }

    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: AppConfig.firebaseApiKey,
        appId: AppConfig.firebaseAppId,
        messagingSenderId: AppConfig.firebaseMessagingSenderId,
        projectId: AppConfig.firebaseProjectId,
        authDomain: AppConfig.firebaseAuthDomain.isEmpty
            ? null
            : AppConfig.firebaseAuthDomain,
        storageBucket: AppConfig.firebaseStorageBucket.isEmpty
            ? null
            : AppConfig.firebaseStorageBucket,
        measurementId: AppConfig.firebaseMeasurementId.isEmpty
            ? null
            : AppConfig.firebaseMeasurementId,
        iosBundleId: AppConfig.firebaseIosBundleId.isEmpty
            ? null
            : AppConfig.firebaseIosBundleId,
      ),
    );

    if (kIsWeb && AppConfig.firebaseAppCheckSiteKey.isNotEmpty) {
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider(AppConfig.firebaseAppCheckSiteKey),
      );
    }
  }

  static bool _hasInitializedApp() {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      // On web, Firebase.apps can touch the JS SDK before FlutterFire loads it.
      // Firebase.initializeApp below is responsible for loading that runtime.
      return false;
    }
  }
}

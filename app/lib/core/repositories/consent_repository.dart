import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

abstract class ConsentRepository {
  Future<void> registerConsent();
}

class LocalConsentRepository implements ConsentRepository {
  const LocalConsentRepository();

  @override
  Future<void> registerConsent() async {
    return;
  }
}

class FirebaseConsentRepository implements ConsentRepository {
  FirebaseConsentRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> registerConsent() async {
    if (Firebase.apps.isEmpty) {
      throw StateError(
        'Firebase nao esta configurado. Rode o app com os dart-defines do projeto.',
      );
    }

    if (!AppConfig.enableRemoteConsent) {
      return;
    }

    final consentId = 'consent_${DateTime.now().millisecondsSinceEpoch}';
    await _firestore.collection('consents').doc(consentId).set({
      'accepted_at': FieldValue.serverTimestamp(),
      'term_version': AppConfig.currentTermsVersion,
      'platform': defaultTargetPlatform.name,
      'agreed': true,
      'app_version': AppConfig.appVersion,
      'source': 'flutter_web',
    });
  }
}

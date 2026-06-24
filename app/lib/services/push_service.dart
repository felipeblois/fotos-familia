import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushService {
  static const String topicName = 'novas-fotos';

  Future<void> enrollFCM() async {
    if (Firebase.apps.isEmpty) {
      return;
    }

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final token = await messaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }
    }
  }

  Future<void> optOut() async {
    return;
  }

  Future<void> optIn() async {
    await enrollFCM();
  }

  Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }

    await FirebaseFirestore.instance.collection('fcm_tokens').doc(uid).set({
      'token': token,
      'platform': defaultTargetPlatform.name,
      'topic': topicName,
      'is_web': kIsWeb,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

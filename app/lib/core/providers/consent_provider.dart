import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/push_service.dart';
import '../config/app_config.dart';
import '../repositories/consent_repository.dart';

final consentRepoProvider = Provider<ConsentRepository>((ref) {
  if (AppConfig.enableRemoteConsent) {
    return FirebaseConsentRepository();
  }
  return const LocalConsentRepository();
});

class ConsentNotifier extends AsyncNotifier<bool> {
  static const _sharedKey = 'neviim_accepted_term_version';

  @override
  Future<bool> build() async {
    if (AppConfig.bypassConsent) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    final cachedVersion = prefs.getString(_sharedKey);
    return cachedVersion == AppConfig.currentTermsVersion;
  }

  Future<bool> agreeToTerms() async {
    if (AppConfig.bypassConsent) {
      state = const AsyncValue.data(true);
      return true;
    }

    state = const AsyncValue.loading();
    try {
      final repo = ref.read(consentRepoProvider);
      await repo.registerConsent();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sharedKey, AppConfig.currentTermsVersion);

      if (AppConfig.enablePushEnrollment) {
        final pushService = PushService();
        await pushService.enrollFCM();
      }

      state = const AsyncValue.data(true);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}

final consentProvider = AsyncNotifierProvider<ConsentNotifier, bool>(
  ConsentNotifier.new,
);

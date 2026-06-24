import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neviim/core/providers/consent_provider.dart';
import 'package:neviim/core/repositories/consent_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeConsentRepository implements ConsentRepository {
  int registerCalls = 0;

  @override
  Future<void> registerConsent() async {
    registerCalls += 1;
  }
}

void main() {
  test('ConsentNotifier salva aceite local quando repository conclui', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repo = FakeConsentRepository();
    final container = ProviderContainer(
      overrides: [
        consentRepoProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(consentProvider.notifier);
    final accepted = await notifier.agreeToTerms();

    expect(accepted, isTrue);
    expect(repo.registerCalls, 1);
    expect(container.read(consentProvider).value, isTrue);
  });
}

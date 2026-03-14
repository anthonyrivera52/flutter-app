import 'package:flutter_app/core/storage/key_value_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final keyValueStorageProvider = Provider((ref) => KeyValueStorage());

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final storage = ref.watch(keyValueStorageProvider);
  return OnboardingNotifier(storage);
});

class OnboardingNotifier extends StateNotifier<bool> {
  final KeyValueStorage _storage;

  OnboardingNotifier(this._storage) : super(false) {
    _loadOnboardingStatus();
  }

  Future<void> _loadOnboardingStatus() async {
    state = await _storage.isOnboardingCompleted();
  }

  Future<void> completeOnboarding() async {
    await _storage.setOnboardingCompleted(true);
    state = true;
  }
}

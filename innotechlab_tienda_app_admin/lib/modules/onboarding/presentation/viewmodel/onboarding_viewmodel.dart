import 'package:flutter_app/core/services/service_locator.dart';
import 'package:flutter_app/modules/onboarding/domain/usecase/set_onboarding_completed.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingState {
  final bool isCompleted;

  OnboardingState({this.isCompleted = false});
}

class OnboardingViewModel extends StateNotifier<OnboardingState> {
  final SetOnboardingCompleted setOnboardingCompleted;

  OnboardingViewModel(this.setOnboardingCompleted) : super(OnboardingState());

  Future<void> completeOnboarding() async {
    await setOnboardingCompleted();
    state = OnboardingState(isCompleted: true);
  }
}

final onboardingViewModelProvider = StateNotifierProvider<OnboardingViewModel, OnboardingState>((ref) {
  return OnboardingViewModel(ref.read(setOnboardingCompletedProvider));
});
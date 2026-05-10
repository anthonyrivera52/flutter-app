import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/features/auth/presentation/viewmodels/sign_up_viewmodel.dart';
import 'package:flutter_app/presentation/widget/common/custom_button.dart';
import 'package:flutter_app/presentation/widget/common/custom_text_field.dart';
import 'package:flutter_app/presentation/widget/common/info_toast.dart';
import 'package:flutter_app/presentation/widget/common/loading_indicator.dart';
import 'package:flutter_app/core/security/security_service.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  late VoidCallback _removeListener;
  String? _previousLoggedInEmail;

  @override
  void initState() {
    super.initState();

    final authVM = ref.read(authViewModelProvider.notifier);

    _removeListener = authVM.addListener((state) {
      if (state.isAuthenticated) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          showInfoToast(
            context,
            message: l10n.welcomeMessage,
            backgroundColor: Colors.green,
            icon: Icons.check_circle_outline,
            isDismissible: true,
          );
          context.go('/');
        }
        return;
      }

      if (state.loggedInEmail != null &&
          state.loggedInEmail!.isNotEmpty &&
          state.loggedInEmail != _previousLoggedInEmail &&
          state.errorMessage == null) {
        _previousLoggedInEmail = state.loggedInEmail;
        if (mounted) {
          showInfoToast(
            context,
            message: 'Código enviado a ${state.loggedInEmail}',
            backgroundColor: Colors.blue,
            icon: Icons.mark_email_read_outlined,
            isDismissible: true,
          );
          context.go('/otp-verification', extra: state.loggedInEmail);
        }
        return;
      }

      if (state.errorMessage != null) {
        if (mounted) {
          showInfoToast(
            context,
            message: state.errorMessage!,
            backgroundColor: Colors.red,
            icon: Icons.error_outline,
            isDismissible: true,
          );
          authVM.clearErrorMessage();
        }
      }
    });
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  void _onSignInButtonPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authViewModelProvider.notifier).login();
    }
  }

  void _onOtpSignInPressed() {
    final email = ref.read(authViewModelProvider.notifier).emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      showInfoToast(
        context,
        message: 'Ingresa un correo válido',
        backgroundColor: Colors.red,
      );
      return;
    }
    ref.read(authViewModelProvider.notifier).signInWithOtp(email);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Observe the ViewModel's state to rebuild the UI when it changes.
    final authState = ref.watch(authViewModelProvider);
    // Access the ViewModel's notifier to call its methods.
    final authVM = ref.read(authViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginTitle), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.loginWelcome,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                CustomTextField(
                  controller:
                      authVM.emailController, // Use the ViewModel's controller
                  labelText: l10n.emailLabel,
                  hintText: l10n.emailHint,
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.emailRequired;
                    }
                    if (!SecurityService.isValidEmail(value)) {
                      return l10n.invalidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: authVM
                      .passwordController, // Use the ViewModel's controller
                  labelText: l10n.passwordLabel,
                  hintText: l10n.passwordHint,
                  prefixIcon: Icons.lock,
                  obscureText: authState
                      .isPasswordObscured, // Observe the ViewModel's state
                  textInputAction: TextInputAction.done,
                  suffixIcon: IconButton(
                    icon: Icon(
                      authState.isPasswordObscured
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.greyMedium,
                    ),
                    onPressed: () {
                      authVM
                          .togglePasswordVisibility(); // Call the ViewModel's method
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.passwordRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                authState
                        .isLoading // Use the ViewModel's loading state
                    ? const LoadingIndicator()
                    : CustomButton(
                        text: l10n.loginButton,
                        onPressed:
                            _onSignInButtonPressed, // Call the method that interacts with the ViewModel
                      ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    context.go('/signup');
                  },
                  child: Text(
                    l10n.dontHaveAccount,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

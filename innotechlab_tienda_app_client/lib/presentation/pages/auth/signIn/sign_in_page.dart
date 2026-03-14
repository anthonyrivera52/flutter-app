import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/presentation/pages/auth/signUp/sign_up_viewmodel.dart';
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
  // Stores the function to remove the listener for authentication state
  late VoidCallback _removeAuthListener;
  // Stores the function to remove the listener for error messages
  late VoidCallback _removeErrorListener;

  @override
  void initState() {
    super.initState();

    // Get the notifier instance for authViewModelProvider
    final authVM = ref.read(authViewModelProvider.notifier);

    // Listen to changes in the authentication state
    _removeAuthListener = authVM.addListener((state) {
      // previousState is not directly available with addListener,
      // so we check if isAuthenticated just became true.
      // This relies on the ViewModel correctly setting isAuthenticated to false initially
      // and then true only on success.
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
      }
    });

    // Listen to changes in the error message state
    _removeErrorListener = authVM.addListener((state) {
      // Check if there's a new error message
      // We need to compare with the previous state to avoid showing the same error repeatedly
      // This is a common pattern when using addListener for SnackBar messages.
      // For a more robust comparison, you might need to store the previous error message
      // in the state of _SignInPageState or rely on clearErrorMessage.
      if (state.errorMessage != null) {
        if (mounted) {
          // Show the error message using InfoToast
          showInfoToast(
            // Usando InfoToast para el mensaje de éxito
            context,
            message: state.errorMessage!,
            backgroundColor: Colors.red,
            icon: Icons.error_outline,
            isDismissible: true,
          );
          // Clear the error message in the ViewModel after displaying it
          authVM.clearErrorMessage();
        }
      }
    });
  }

  @override
  void dispose() {
    // Close the listeners when the widget is disposed
    _removeAuthListener();
    _removeErrorListener();
    // Text controllers are managed and disposed by the ViewModel.
    // No need to dispose them here.
    super.dispose();
  }

  void _onSignInButtonPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      // Call the login method of the ViewModel
      ref.read(authViewModelProvider.notifier).login();
    }
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

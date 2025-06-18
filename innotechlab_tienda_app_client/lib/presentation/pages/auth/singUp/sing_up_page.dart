import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/presentation/pages/auth/singUp/sing_up_viewmodel.dart';
import 'package:flutter_app/presentation/widget/common/custom_button.dart';
import 'package:flutter_app/presentation/widget/common/custom_text_field.dart';
import 'package:flutter_app/presentation/widget/common/info_toast.dart';
import 'package:flutter_app/presentation/widget/common/loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  // Estos estados locales de la UI para la visibilidad de la contraseña
  // se mantienen aquí, ya que no se pidió moverlos al ViewModel.
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Stores the function to remove the listener for authentication state
  late VoidCallback _removeAuthListener;
  // Stores the function to remove the listener for error messages
  late VoidCallback _removeErrorListener;
  
  @override
  void initState() {
    super.initState();

    // Get the notifier instance for authViewModelProvider
    final authVM = ref.read(authViewModelProvider.notifier); // Usar authViewModelProvider

    // Listen to changes in the authentication state
    _removeAuthListener = authVM.addListener((state) {
      // previousState is not directly available with addListener,
      // so we check if isAuthenticated just became true.
      // This relies on the ViewModel correctly setting isAuthenticated to false initially
      // and then true only on success.
      if (state.isAuthenticated) {
        if (mounted) {
          showInfoToast( // Usando InfoToast para el mensaje de éxito
            context,
            message: '¡Registro exitoso!',
            backgroundColor: Colors.green,
            icon: Icons.check_circle_outline,
            isDismissible: true
          );
          // Redirect to the OTP verification page or main page
          // Ensure '/otp-verification' is defined in your GoRouter
          context.go('/otp-verification', extra: state.loggedInEmail);
        }
      }
    });

    // Listen to changes in the error message state
    _removeErrorListener = authVM.addListener((state) {
      // Check if there's a new error message
      if (state.errorMessage != null) {
        if (mounted) {
          showInfoToast( // Usando InfoToast para el mensaje de éxito
            context,
            message: state.errorMessage!,
            backgroundColor: Colors.red,
            icon: Icons.error_outline,
            isDismissible: true
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

  void _onSignUpButtonPressed() { // Renombrado para claridad
    if (_formKey.currentState?.validate() ?? false) {
      // Llama al método de registro del ViewModel
      ref.read(authViewModelProvider.notifier).signUp(); // Usar authViewModelProvider
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider); // Usar authViewModelProvider
    final authVM = ref.read(authViewModelProvider.notifier); // Usar authViewModelProvider

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrarse'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Crea una cuenta',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 30),
                CustomTextField(
                  controller: authVM.displayNameController,
                  labelText: 'Nombre (Opcional)',
                  hintText: 'Ej. Juan Pérez',
                  prefixIcon: Icons.person,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: authVM.emailController,
                  labelText: 'Correo Electrónico',
                  hintText: 'ejemplo@dominio.com',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El correo es requerido';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Introduce un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: authVM.passwordController,
                  labelText: 'Contraseña',
                  hintText: 'Mínimo 6 caracteres',
                  prefixIcon: Icons.lock,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.greyMedium,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La contraseña es requerida';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: authVM.confirmPasswordController,
                  labelText: 'Confirmar Contraseña',
                  hintText: 'Repite tu contraseña',
                  prefixIcon: Icons.lock,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.greyMedium,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirma tu contraseña';
                    }
                    // La validación de coincidencia debe hacerse contra el texto del controlador de contraseña
                    if (value != authVM.passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                authState.isLoading
                    ? const LoadingIndicator()
                    : CustomButton(
                        text: 'Registrarse',
                        onPressed: _onSignUpButtonPressed, // CORREGIDO: Llama a la función directamente
                      ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    context.go('/signin');
                  },
                  child: Text(
                    '¿Ya tienes una cuenta? Iniciar Sesión',
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary),
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

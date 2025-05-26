import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_tienda/core/utils/from_validator.dart';
import 'package:mi_tienda/presentation/providers/auth_provider.dart';
import 'package:mi_tienda/core/utils/app_colors.dart';
import 'package:mi_tienda/presentation/widgets/common/custom_button.dart';
import 'package:mi_tienda/presentation/widgets/common/custom_text_field.dart';
import 'package:mi_tienda/presentation/widgets/common/loading_indicator.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final authNotifier = ref.read(authProvider.notifier);
      final success = await authNotifier.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success) {
        // Redirigir a la página de verificación OTP después del inicio de sesión exitoso
        // Pasamos el email para pre-llenar el campo en la página de OTP
        context.go('/otp-verification', extra: _emailController.text.trim());
      } else {
        // Mostrar mensaje de error (ej., SnackBar)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authNotifier.errorMessage ?? 'Error al iniciar sesión'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
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
                const Icon(
                  Icons.lock_open,
                  size: 80,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(height: 30),
                Text(
                  'Bienvenido de nuevo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                ),
                const SizedBox(height: 30),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Correo electrónico',
                  keyboardType: TextInputType.emailAddress,
                  // validator: FormValidators.validateEmail, // Usando validador
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Contraseña',
                  obscureText: true,
                  // validator: FormValidators.validatePassword, // Usando validador
                ),
                const SizedBox(height: 30),
                authState.isLoading
                    ? const LoadingIndicator()
                    : CustomButton(
                        text: 'Iniciar Sesión',
                        onPressed: _login,
                      ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    context.go('/signup');
                  },
                  child: const Text(
                    '¿No tienes cuenta? Regístrate aquí',
                    style: TextStyle(color: AppColors.primaryColor),
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_tienda/presentation/providers/auth_provider.dart';
import 'package:mi_tienda/presentation/widgets/common/custom_text_field.dart';
import 'package:mi_tienda/presentation/widgets/common/custom_button.dart';
import 'package:mi_tienda/presentation/widgets/common/loading_indicator.dart';
import 'package:mi_tienda/core/utils/app_colors.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authNotifier = ref.read(authProvider.notifier);

      await authNotifier.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: _displayNameController.text.trim().isEmpty ? null : _displayNameController.text.trim(),
      );

      final newState = ref.read(authProvider);
      if (newState.isAuthenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Registro exitoso!')),
          );
          context.go('/');
        }
      } else if (newState.errorMessage != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(newState.errorMessage!)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

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
                  controller: _displayNameController,
                  labelText: 'Nombre (Opcional)',
                  hintText: 'Ej. Juan Pérez',
                  prefixIcon: Icons.person,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
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
                  controller: _passwordController,
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
                  controller: _confirmPasswordController,
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
                    if (value != _passwordController.text) {
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
                        onPressed: _signUp,
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

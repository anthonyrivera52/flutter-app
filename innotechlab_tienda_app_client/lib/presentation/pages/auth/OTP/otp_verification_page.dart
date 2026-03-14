import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/presentation/pages/auth/signUp/sign_up_viewmodel.dart';
import 'package:flutter_app/presentation/widget/common/custom_button.dart';
import 'package:flutter_app/presentation/widget/common/custom_text_field.dart';
import 'package:flutter_app/presentation/widget/common/info_toast.dart';
import 'package:flutter_app/presentation/widget/common/loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OtpVerificationPage extends ConsumerStatefulWidget {
  final String? email; // Email para pre-llenar el campo

  const OtpVerificationPage({super.key, this.email});

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showInfoToast(
        context,
        message: 'Ingresa un correo',
        backgroundColor: Colors.red,
      );
      return;
    }

    await ref.read(authViewModelProvider.notifier).resendOtp(email);
    if (mounted) {
      showInfoToast(
        context,
        message: 'OTP reenviado',
        backgroundColor: Colors.green,
      );
    }
  }

  void _verifyOtp() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final success = await ref
        .read(authViewModelProvider.notifier)
        .verifyOtp(_emailController.text.trim(), _otpController.text.trim());

    if (success && mounted) {
      // Navigate to location selection instead of directly to home
      context.go('/location-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Verificación OTP'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.vpn_key,
                  size: 80,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(height: 30),
                Text(
                  'Ingresa el código OTP',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Hemos enviado un código a tu correo electrónico. Por favor, ingrésalo a continuación.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 30),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Correo electrónico',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El correo electrónico es requerido';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Introduce un correo electrónico válido';
                    }
                    return null;
                  },
                  prefixIcon: Icons.email,
                  hintText: '',
                  readOnly:
                      widget.email != null, // Make read-only if email is passed
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _otpController,
                  labelText: 'Código OTP',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El código OTP es requerido';
                    }
                    if (value.length != 6) {
                      return 'El código OTP debe tener 6 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                authState.isLoading
                    ? const LoadingIndicator()
                    : Column(
                        children: [
                          CustomButton(
                            text: 'Verificar OTP',
                            onPressed: _verifyOtp,
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _sendOtp,
                            child: const Text(
                              'Reenviar OTP',
                              style: TextStyle(color: AppColors.primaryColor),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

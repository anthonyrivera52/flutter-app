import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/presentation/pages/auth/signIn/singIn_viewmodel.dart';
import 'package:flutter_app/presentation/widget/common/custom_button.dart';
import 'package:flutter_app/presentation/widget/common/custom_text_field.dart';
import 'package:flutter_app/presentation/widget/common/loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OtpVerificationPage extends ConsumerStatefulWidget {
  final String? email; // Email para pre-llenar el campo

  const OtpVerificationPage({super.key, this.email});

  @override
  ConsumerState<OtpVerificationPage> createState() => _OtpVerificationPageState();
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

  // void _sendOtp() async {
  //   if (FormValidators.isValidateEmail(_emailController.text) != null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Por favor, introduce un correo electrónico válido.')),
  //     );
  //     return;
  //   }

  //   final authNotifier = ref.read(authProvider.notifier);
  //   final success = await authNotifier.sendOtpForVerification(_emailController.text.trim());

  //   if (success) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('OTP enviado a tu correo electrónico.')),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(authNotifier.errorMessage ?? 'Error al enviar OTP'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  void _verifyOtp() async {
    context.go('/'); // Redirigir a home si la verificación es exitosa

    // if (_formKey.currentState!.validate()) {
    //   final authNotifier = ref.read(authProvider.notifier);
    //   final success = await authNotifier.verifyOtp(
    //     _emailController.text.trim(),
    //     _otpController.text.trim(),
    //   );

    //   if (success) {
    //     context.go('/'); // Redirigir a home si la verificación es exitosa
    //   } else {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text(authNotifier.errorMessage ?? 'Error al verificar OTP'),
    //         backgroundColor: Colors.red,
    //       ),
    //     );
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verificación OTP'),
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
                  readOnly: widget.email != null, // Make read-only if email is passed
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
                            // onPressed: _sendOtp,
                            onPressed: _verifyOtp,
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
// lib/view/phone_auth_screen.dart
// Pantalla de autenticación con teléfono y OTP

import 'package:flutter/material.dart';
import 'package:delivery_app_mvvm/core/utils/constants.dart';
import 'package:delivery_app_mvvm/service/otp_service.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final OtpService _otpService = OtpServiceImpl();

  bool _isLogin = true;
  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _phoneNumber = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Ingresa tu número de teléfono');
      return;
    }

    // Formatear número (agregar código de país si no tiene)
    String formattedPhone = phone;
    if (!phone.startsWith('+')) {
      if (phone.startsWith('57')) {
        formattedPhone = '+$phone';
      } else {
        formattedPhone = '+57$phone';
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _phoneNumber = formattedPhone;
    });

    final result = await _otpService.sendOtp(formattedPhone);

    setState(() {
      _isLoading = false;
      if (result.success) {
        _isOtpSent = true;
        _errorMessage = null;
      } else {
        _errorMessage = result.message;
      }
    });
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();

    if (code.isEmpty) {
      setState(() => _errorMessage = 'Ingresa el código OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _otpService.verifyOtp(_phoneNumber, code);

    setState(() {
      _isLoading = false;
      if (result.success) {
        // Aquí redirigir según corresponda
        // Para desarrollo, siempre succeede
        _showSuccessAndClose();
      } else {
        _errorMessage = result.message;
      }
    });
  }

  void _showSuccessAndClose() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Éxito'),
        content: Text(
          AppConstants.isDevelopment
              ? 'Código verificado correctamente.\n\nEn desarrollo, cualquier código es válido.'
              : 'Teléfono verificado correctamente.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close auth screen
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _showDevCodeHint() {
    if (!AppConstants.isDevelopment) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Código de desarrollo: ${AppConstants.devOtpCode}'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Iniciar Sesión' : 'Registrarse'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de teléfono
            Icon(
              Icons.phone_android,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 20),

            // Título
            Text(
              _isOtpSent ? 'Ingresa el código' : 'Ingresa tu teléfono',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Subtítulo
            Text(
              _isOtpSent
                  ? 'Te enviamos un código a $_phoneNumber'
                  : 'Usaremos este número para identificarte',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            if (!_isOtpSent) ...[
              // Campo de teléfono
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Número de teléfono',
                  hintText: '3001234567',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                  suffixIcon: _phoneController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _phoneController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // Botón enviar código
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Enviar código',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ] else ...[
              // Campo de OTP
              TextField(
                controller: _otpController,
                decoration: InputDecoration(
                  labelText: 'Código de verificación',
                  hintText: '123456',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _sendOtp,
                    tooltip: 'Reenviar código',
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                onChanged: (value) {
                  // Auto-verificar cuando tenga 6 dígitos
                  if (value.length == 6) {
                    _verifyOtp();
                  }
                },
              ),
              const SizedBox(height: 20),

              // Indicador de desarrollo
              if (AppConstants.isDevelopment)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Modo desarrollo: código ${AppConstants.devOtpCode}',
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Botón verificar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Verificar',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 15),

              // Reenviar código
              TextButton(
                onPressed: _sendOtp,
                child: const Text('¿No recibiste el código? Reenviar'),
              ),
            ],

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Toggle login/register
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                  _isOtpSent = false;
                  _errorMessage = null;
                });
              },
              child: Text(
                _isLogin
                    ? '¿No tienes cuenta? Regístrate'
                    : '¿Ya tienes cuenta? Inicia sesión',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

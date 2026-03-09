// lib/service/otp_service.dart
// Servicio de OTP que soporta Supabase (desarrollo) y Twilio (producción)

import 'package:flutter/foundation.dart';
import 'package:delivery_app_mvvm/core/utils/constants.dart';

abstract class OtpService {
  Future<OtpResult> sendOtp(String phoneNumber);
  Future<OtpResult> verifyOtp(String phoneNumber, String code);
}

class OtpResult {
  final bool success;
  final String message;
  final String? errorCode;

  OtpResult({
    required this.success,
    required this.message,
    this.errorCode,
  });

  factory OtpResult.success(String message) {
    return OtpResult(success: true, message: message);
  }

  factory OtpResult.error(String message, {String? errorCode}) {
    return OtpResult(success: false, message: message, errorCode: errorCode);
  }
}

/// Implementación de OTP que selecciona el método según la configuración
class OtpServiceImpl implements OtpService {
  // Instancia de Twilio (solo se usa en producción)
  TwilioOtpService? _twilioService;

  OtpServiceImpl() {
    if (AppConstants.isTwilioOtp) {
      _twilioService = TwilioOtpService();
    }
  }

  @override
  Future<OtpResult> sendOtp(String phoneNumber) async {
    debugPrint('OTP: Enviando código a $phoneNumber');
    debugPrint('OTP Method: ${AppConstants.otpMethod}');

    if (AppConstants.isSupabaseOtp) {
      // En desarrollo: Simular envío de OTP o usar código fijo
      return _sendDevOtp(phoneNumber);
    } else if (AppConstants.isTwilioOtp) {
      // En producción: Usar Twilio
      return await _twilioService?.sendOtp(phoneNumber) ??
          OtpResult.error('Servicio Twilio no configurado');
    } else {
      return OtpResult.error('Método OTP no configurado');
    }
  }

  @override
  Future<OtpResult> verifyOtp(String phoneNumber, String code) async {
    debugPrint('OTP: Verificando código $code para $phoneNumber');

    if (AppConstants.isSupabaseOtp) {
      return _verifyDevOtp(code);
    } else if (AppConstants.isTwilioOtp) {
      return await _twilioService?.verifyOtp(phoneNumber, code) ??
          OtpResult.error('Servicio Twilio no configurado');
    } else {
      return OtpResult.error('Método OTP no configurado');
    }
  }

  // Desarrollo: Simular envío (o usar Supabase real)
  Future<OtpResult> _sendDevOtp(String phoneNumber) async {
    // En desarrollo, siempre succeede
    debugPrint('OTP (DESARROLLO): Simulando envío de código a $phoneNumber');
    debugPrint('OTP (DESARROLLO): Código de verificación: ${AppConstants.devOtpCode}');

    return OtpResult.success(
      'Código enviado (desarrollo). Usa: ${AppConstants.devOtpCode}',
    );
  }

  // Desarrollo: Verificar con código fijo
  Future<OtpResult> _verifyDevOtp(String code) async {
    if (code == AppConstants.devOtpCode) {
      return OtpResult.success('Código verificado correctamente');
    }
    return OtpResult.error('Código inválido');
  }
}

/// Implementación de Twilio OTP
/// Para usar Twilio en producción, necesitas:
/// 1. Cuenta de Twilio con Verify API
/// 2. Credenciales en variables de entorno
class TwilioOtpService implements OtpService {
  @override
  Future<OtpResult> sendOtp(String phoneNumber) async {
    try {
      // Implementación de Twilio (requiere paquete twilio_flutter o similar)
      // Por ahora, retornamos un resultado de ejemplo
      // TODO: Implementar con twilio_verify_flutter o http client

      if (AppConstants.twilioAccountSid.isEmpty ||
          AppConstants.twilioAuthToken.isEmpty) {
        return OtpResult.error(
          'Credenciales de Twilio no configuradas',
          errorCode: 'TWILIO_NOT_CONFIGURED',
        );
      }

      // Aquí iría la implementación real con Twilio
      // final twilioClient = TwilioVerify(
      //   accountSid: AppConstants.twilioAccountSid,
      //   authToken: AppConstants.twilioAuthToken,
      // );
      // await twilioClient.verifications.create(
      //   to: phoneNumber,
      //   channel: 'sms',
      // );

      debugPrint('Twilio: Enviando OTP a $phoneNumber');

      return OtpResult.success('Código enviado por SMS');
    } catch (e) {
      debugPrint('Twilio OTP Error: $e');
      return OtpResult.error(
        'Error al enviar código: ${e.toString()}',
        errorCode: 'TWILIO_ERROR',
      );
    }
  }

  @override
  Future<OtpResult> verifyOtp(String phoneNumber, String code) async {
    try {
      if (AppConstants.twilioAccountSid.isEmpty ||
          AppConstants.twilioAuthToken.isEmpty) {
        return OtpResult.error(
          'Credenciales de Twilio no configuradas',
          errorCode: 'TWILIO_NOT_CONFIGURED',
        );
      }

      // Implementación real con Twilio
      // final twilioClient = TwilioVerify(
      //   accountSid: AppConstants.twilioAccountSid,
      //   authToken: AppConstants.twilioAuthToken,
      // );
      // final verification = await twilioClient.verificationCheck.create(
      //   to: phoneNumber,
      //   code: code,
      // );
      // if (verification.status == 'approved') {
      //   return OtpResult.success('Verificación exitosa');
      // }

      debugPrint('Twilio: Verificando código $code para $phoneNumber');

      // Simulación para demo
      if (code.length == 6) {
        return OtpResult.success('Verificación exitosa');
      }

      return OtpResult.error('Código incorrecto', errorCode: 'INVALID_CODE');
    } catch (e) {
      debugPrint('Twilio Verify Error: $e');
      return OtpResult.error(
        'Error al verificar código: ${e.toString()}',
        errorCode: 'TWILIO_ERROR',
      );
    }
  }
}

/// Servicio de verificación de código usando Supabase Auth
/// Este se usa para verificación de teléfono con Supabase
class SupabaseOtpService implements OtpService {
  // Supabase ya maneja esto automáticamente con signInWithOtp
  // Esta clase es para extendido control

  @override
  Future<OtpResult> sendOtp(String phoneNumber) async {
    try {
      // El método de Supabase para OTP es signInWithOtp
      // que envía un código al teléfono
      debugPrint('Supabase OTP: Solicitando código para $phoneNumber');

      // Retornar success - Supabase maneja el envío automáticamente
      return OtpResult.success('Código enviado a tu teléfono');
    } catch (e) {
      debugPrint('Supabase OTP Error: $e');
      return OtpResult.error('Error al enviar código: ${e.toString()}');
    }
  }

  @override
  Future<OtpResult> verifyOtp(String phoneNumber, String code) async {
    try {
      // La verificación se hace cuando el usuario ingresa el código
      // y llama a signInWithOtp con el código
      debugPrint('Supabase OTP: Verificando código para $phoneNumber');

      // El código se verifica en el cliente de Supabase
      return OtpResult.success('Código verificado');
    } catch (e) {
      return OtpResult.error('Código incorrecto o expirado');
    }
  }
}

import 'package:email_validator/email_validator.dart';

class FormValidators {
  static String? isValidateEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo no puede estar vacío.';
    }
    return null;
  }

  static String? isValidateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, introduce tu correo electrónico.';
    }
    if (!EmailValidator.validate(value)) {
      return 'Correo electrónico inválido.';
    }
    return null;
  }

  static String? isValidatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, introduce tu contraseña.';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    return null;
  }

  static String? isValidateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, introduce el código OTP.';
    }
    if (value.length != 6 || int.tryParse(value) == null) {
      return 'El OTP debe ser un número de 6 dígitos.';
    }
    return null;
  }

}
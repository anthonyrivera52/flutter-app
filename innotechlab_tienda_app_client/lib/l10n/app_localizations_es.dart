// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Innotech Tienda';

  @override
  String get loginTitle => 'Iniciar Sesión';

  @override
  String get loginWelcome => 'Bienvenido de nuevo';

  @override
  String get emailLabel => 'Correo Electrónico';

  @override
  String get emailHint => 'ejemplo@dominio.com';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get passwordHint => 'Tu contraseña secreta';

  @override
  String get loginButton => 'Iniciar Sesión';

  @override
  String get dontHaveAccount => '¿No tienes una cuenta? Regístrate';

  @override
  String get registerTitle => 'Registrarse';

  @override
  String get registerButton => 'Registrarse';

  @override
  String get emailRequired => 'El correo es requerido';

  @override
  String get invalidEmail => 'Introduce un correo válido';

  @override
  String get passwordRequired => 'La contraseña es requerida';

  @override
  String get welcomeMessage => '¡Bienvenido!';

  @override
  String get unexpectedError => 'Error inesperado';

  @override
  String get invalidCredentials =>
      'Credenciales incorrectas. Inténtalo de nuevo.';
}

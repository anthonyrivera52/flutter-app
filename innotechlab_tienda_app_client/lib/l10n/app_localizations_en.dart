// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Innotech Store';

  @override
  String get loginTitle => 'Sign In';

  @override
  String get loginWelcome => 'Welcome back';

  @override
  String get emailLabel => 'Email address';

  @override
  String get emailHint => 'example@domain.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Your secret password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Sign Up';

  @override
  String get registerTitle => 'Sign Up';

  @override
  String get registerButton => 'Sign Up';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get welcomeMessage => 'Welcome!';

  @override
  String get unexpectedError => 'Unexpected error';

  @override
  String get invalidCredentials => 'Invalid credentials. Try again.';
}

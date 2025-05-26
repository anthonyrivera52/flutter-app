import 'package:flutter/material.dart';

class AppColors {
  // Colores primarios (de tu marca)
  static const Color primaryColor = Color(0xFF007BFF); // Un azul vibrante
  static const Color primaryDarkColor = Color(0xFF0056B3); // Una versión más oscura del primario
  static const Color primaryLightColor = Color(0xFFCCE5FF); // Una versión más clara del primario

  // Colores secundarios (para acentos, botones de acción, etc.)
  static const Color secondaryColor = Color(0xFFFFC107); // Un amarillo/naranja
  static const Color secondaryDarkColor = Color(0xFFD39E00);
  static const Color secondaryLightColor = Color(0xFFFFECB3);

  // Colores de texto
  static const Color textColor = Color(0xFF333333); // Gris oscuro casi negro
  static const Color textLightColor = Color(0xFF6C757D); // Gris medio
  static const Color textDarkColor = Color(0xFF212529); // Gris muy oscuro

  // Colores de fondo y superficies
  static const Color backgroundColor = Color(0xFFF8F9FA); // Blanco grisáceo muy claro
  static const Color cardColor = Color(0xFFFFFFFF); // Blanco puro para tarjetas/superficies

  // Colores de estado/feedback
  static const Color successColor = Color(0xFF28A745); // Verde para éxito
  static const Color errorColor = Color(0xFFDC3545); // Rojo para errores
  static const Color warningColor = Color(0xFFFFC107); // Amarillo para advertencias (puede ser igual al secundario)
  static const Color infoColor = Color(0xFF17A2B8); // Azul claro para información

  // Colores grises para bordes, divisores, iconos inactivos, etc.
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyMedium = Color(0xFFB0B0B0);
  static const Color greyDark = Color(0xFF757575);

  // Colores para sombra (ej. para Card o BoxShadow)
  static const Color shadowColor = Color(0x33000000); // Negro con 20% de opacidad

  // Puedes añadir más si tu diseño lo requiere, por ejemplo:
  // static const Color accentColor1 = Color(0xFF...),
  // static const Color accentColor2 = Color(0xFF...),
}
import 'package:flutter/material.dart';

/// Un widget de tipo SnackBar personalizado para mostrar mensajes informativos.
///
/// [context] El BuildContext actual para mostrar el SnackBar.
/// [message] El texto principal del mensaje a mostrar.
/// [backgroundColor] El color de fondo del SnackBar (por defecto, gris oscuro).
/// [textColor] El color del texto del mensaje (por defecto, blanco).
/// [icon] Un icono opcional para mostrar junto al mensaje.
/// [duration] La duración que el SnackBar estará visible (por defecto, 4 segundos).
void showInfoToast(
  BuildContext context, {
  required String message,
  Color backgroundColor = Colors.grey,
  Color textColor = Colors.white,
  IconData? icon,
  Duration duration = const Duration(seconds: 5),
  bool? isDismissible,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating, // Opcional: para que flote sobre el contenido
      action: isDismissible == true
          ? SnackBarAction(
              label: 'Cerrar',
              textColor: textColor,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            )
          : null, // Si isDismissible es true, muestra un botón de cerrar
    ),
  );
}

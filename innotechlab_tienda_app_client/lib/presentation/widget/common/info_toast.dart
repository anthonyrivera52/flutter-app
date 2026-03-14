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
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: textColor),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(message, style: TextStyle(color: textColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1.0, end: 0.0),
              duration: duration,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor.withValues(alpha: 0.7),
                  ),
                  minHeight: 3,
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior
          .floating, // Opcional: para que flote sobre el contenido
      action: isDismissible == true
          ? SnackBarAction(
              label: 'Cerrar',
              textColor: textColor,
              onPressed: () {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                }
              },
            )
          : null, // Si isDismissible es true, muestra un botón de cerrar
    ),
  );
}

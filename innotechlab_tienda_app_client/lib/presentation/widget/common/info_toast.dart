import 'package:flutter/material.dart';

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

  void dismiss() {
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

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
      behavior: SnackBarBehavior.floating,
      action: isDismissible == true
          ? SnackBarAction(
              label: 'Cerrar',
              textColor: textColor,
              onPressed: dismiss,
            )
          : null,
    ),
  );

  Future.delayed(duration, dismiss);
}

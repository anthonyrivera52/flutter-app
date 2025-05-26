import 'package:flutter/material.dart';
import 'package:mi_tienda/core/utils/app_colors.dart'; // Asegúrate de importar AppColors

class LoadingIndicator extends StatelessWidget {
  final Color? color;
  final double strokeWidth;

  const LoadingIndicator({
    super.key,
    this.color,
    this.strokeWidth = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: color ?? Theme.of(context).colorScheme.primary, // Usa el color primario del tema por defecto
        strokeWidth: strokeWidth,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart';

/// Widget de error visual con imagen para mostrar cuando falla algo
class ErrorDisplayWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String? imagePath;
  final IconData icon;

  const ErrorDisplayWidget({
    super.key,
    this.title = 'Algo salió mal',
    required this.message,
    this.onRetry,
    this.imagePath,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Imagen o ícono de error
            if (imagePath != null)
              Image.asset(
                imagePath!,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => _buildIcon(),
              )
            else
              _buildIcon(),
            const SizedBox(height: 24),
            // Título
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.greyDark,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Mensaje
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.greyMedium,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              // Botón de reintentar
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.errorColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 64,
        color: AppColors.errorColor,
      ),
    );
  }
}

/// Widget de error simplificado para usar en listas
class ErrorListItem extends StatelessWidget {
  final String title;
  final String message;
  final DateTime timestamp;
  final VoidCallback? onTap;

  const ErrorListItem({
    super.key,
    required this.title,
    required this.message,
    required this.timestamp,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.errorColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline,
            color: AppColors.errorColor,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(timestamp),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.greyMedium,
              ),
            ),
          ],
        ),
        trailing: onTap != null
            ? IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: onTap,
              )
            : null,
        isThreeLine: true,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now().toUtc();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Hace un momento';
    } else if (diff.inHours < 1) {
      return 'Hace ${diff.inMinutes} minutos';
    } else if (diff.inDays < 1) {
      return 'Hace ${diff.inHours} horas';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} días';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

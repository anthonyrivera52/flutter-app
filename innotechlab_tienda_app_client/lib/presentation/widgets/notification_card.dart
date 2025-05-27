import 'package:flutter/material.dart';
import 'package:mi_tienda/core/utils/app_colors.dart';
import 'package:intl/intl.dart'; // Para formateo de fechas

class NotificationCard extends StatelessWidget {
  final String title;
  final String body;
  final DateTime timestamp;
  final VoidCallback? onTap;
  final bool isRead;

  const NotificationCard({
    super.key,
    required this.title,
    required this.body,
    required this.timestamp,
    this.onTap,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isRead ? AppColors.cardColor : AppColors.primaryLightColor.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8.0),
              Text(
                body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8.0),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  _formatTimestamp(timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.greyDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return DateFormat('dd/MM/yyyy').format(time);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

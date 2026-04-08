import 'package:flutter/material.dart';
import '../../../core/services/app_config_service.dart';
import '../../../core/utils/app_colors.dart';

class RegionChangeModal extends StatelessWidget {
  final RegionConfig detectedConfig;
  final RegionConfig currentConfig;
  final VoidCallback onAccept;
  final VoidCallback onKeep;

  const RegionChangeModal({
    super.key,
    required this.detectedConfig,
    required this.currentConfig,
    required this.onAccept,
    required this.onKeep,
  });

  static Future<bool?> show(
    BuildContext context, {
    required RegionConfig detectedConfig,
    required RegionConfig currentConfig,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RegionChangeModal(
        detectedConfig: detectedConfig,
        currentConfig: currentConfig,
        onAccept: () => Navigator.of(context).pop(true),
        onKeep: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.location_on, color: AppColors.primaryColor),
          const SizedBox(width: 8),
          const Text('Cambio de ubicación'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detectamos que estás en ${detectedConfig.countryName}.',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '¿Quieres actualizar los precios a ${detectedConfig.currencyCode}?',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildComparisonRow(
                  'País actual',
                  currentConfig.countryName,
                  currentConfig.currencyCode,
                ),
                const SizedBox(height: 8),
                _buildComparisonRow(
                  'Detectado',
                  detectedConfig.countryName,
                  detectedConfig.currencyCode,
                  isHighlighted: true,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onKeep,
          child: Text(
            'Mantener ${currentConfig.countryName}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        ElevatedButton(
          onPressed: onAccept,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('Actualizar a ${detectedConfig.countryName}'),
        ),
      ],
    );
  }

  Widget _buildComparisonRow(
    String label,
    String country,
    String currency, {
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          '$country ($currency)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
            color: isHighlighted ? AppColors.primaryColor : null,
          ),
        ),
      ],
    );
  }
}

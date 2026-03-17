import 'package:flutter/material.dart';
import 'package:flutter_app/features/products/domain/models/location_hour.dart';
import 'package:flutter_app/core/utils/app_colors.dart';

class ScheduleDialog extends StatelessWidget {
  final List<LocationHour> hours;
  final String locationName;

  const ScheduleDialog({
    super.key,
    required this.hours,
    required this.locationName,
  });

  static Future<void> show(
    BuildContext context, {
    required List<LocationHour> hours,
    required String locationName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ScheduleDialog(hours: hours, locationName: locationName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedHours = List<LocationHour>.from(hours)
      ..sort((a, b) => a.weekday.compareTo(b.weekday));

    final today = DateTime.now().weekday % 7;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(context),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sortedHours.length,
              itemBuilder: (context, index) {
                final hour = sortedHours[index];
                final isToday = hour.weekday == today;
                return _buildDayRow(hour, isToday);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.access_time,
              color: AppColors.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Horarios',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  locationName,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRow(LocationHour hour, bool isToday) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.primaryColor.withValues(alpha: 0.08)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: isToday
            ? Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              hour.dayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                color: isToday ? AppColors.primaryColor : Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              hour.formattedSchedule,
              style: TextStyle(
                fontSize: 14,
                color: hour.isOpen ? Colors.black87 : Colors.grey.shade500,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Hoy',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

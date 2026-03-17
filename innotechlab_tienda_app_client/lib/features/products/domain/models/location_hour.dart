import 'package:equatable/equatable.dart';

class LocationHour extends Equatable {
  final int weekday;
  final bool isOpen;
  final String? openTime;
  final String? closeTime;
  final String? openTime1;
  final String? closeTime1;
  final String? openTime2;
  final String? closeTime2;

  const LocationHour({
    required this.weekday,
    required this.isOpen,
    this.openTime,
    this.closeTime,
    this.openTime1,
    this.closeTime1,
    this.openTime2,
    this.closeTime2,
  });

  factory LocationHour.fromJson(Map<String, dynamic> json) {
    return LocationHour(
      weekday: json['weekday'] as int? ?? 0,
      isOpen: json['is_open'] as bool? ?? false,
      openTime: _formatTime(json['open_time']),
      closeTime: _formatTime(json['close_time']),
      openTime1: _formatTime(json['open_time_1']),
      closeTime1: _formatTime(json['close_time_1']),
      openTime2: _formatTime(json['open_time_2']),
      closeTime2: _formatTime(json['close_time_2']),
    );
  }

  static String? _formatTime(dynamic time) {
    if (time == null) return null;
    if (time is String) {
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
      }
    }
    return time.toString();
  }

  String get dayName {
    const days = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
    ];
    return weekday >= 0 && weekday < days.length ? days[weekday] : '';
  }

  String get formattedSchedule {
    if (!isOpen) return 'Cerrado';

    final schedules = <String>[];

    if (openTime != null && closeTime != null) {
      schedules.add('$openTime - $closeTime');
    }
    if (openTime1 != null && closeTime1 != null) {
      schedules.add('$openTime1 - $closeTime1');
    }
    if (openTime2 != null && closeTime2 != null) {
      schedules.add('$openTime2 - $closeTime2');
    }

    return schedules.isNotEmpty ? schedules.join(', ') : 'Cerrado';
  }

  @override
  List<Object?> get props => [
    weekday,
    isOpen,
    openTime,
    closeTime,
    openTime1,
    closeTime1,
    openTime2,
    closeTime2,
  ];
}

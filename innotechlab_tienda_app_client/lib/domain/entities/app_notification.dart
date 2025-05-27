import 'package:equatable/equatable.dart';
import 'dart:convert';

class AppNotification extends Equatable {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.data,
    this.isRead = false,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    Map<String, dynamic>? data,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'isRead': isRead,
    };
  }

  factory AppNotification.fromSupabaseRealtimePayload(Map<String, dynamic> payload) {
    final String rawData = payload['payload'] as String;
    final Map<String, dynamic> customData = jsonDecode(rawData);

    String title = 'Nueva Orden Confirmada';
    String body = 'Orden #${(customData['order_id'] as String).substring(0, 8)} - Total: \$${(customData['total_amount'] as num).toStringAsFixed(2)}';

    return AppNotification(
      id: customData['order_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.parse(customData['created_at'] ?? DateTime.now().toIso8601String()),
      data: customData,
      isRead: false,
    );
  }

  @override
  List<Object?> get props => [id, title, body, timestamp, data, isRead];
}

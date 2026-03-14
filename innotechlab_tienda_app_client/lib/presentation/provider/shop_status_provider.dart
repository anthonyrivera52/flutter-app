import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ShopStatus { active, waiting, inactive, closed }

class ScheduleSlot extends Equatable {
  final bool isOpen;
  final String? openTime;
  final String? closeTime;
  final String? openTime1;
  final String? closeTime1;
  final String? openTime2;
  final String? closeTime2;

  const ScheduleSlot({
    required this.isOpen,
    this.openTime,
    this.closeTime,
    this.openTime1,
    this.closeTime1,
    this.openTime2,
    this.closeTime2,
  });

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) {
    return ScheduleSlot(
      isOpen: json['is_open'] ?? false,
      openTime: json['open_time'],
      closeTime: json['close_time'],
      openTime1: json['open_time_1'],
      closeTime1: json['close_time_1'],
      openTime2: json['open_time_2'],
      closeTime2: json['close_time_2'],
    );
  }

  @override
  List<Object?> get props => [
    isOpen,
    openTime,
    closeTime,
    openTime1,
    closeTime1,
    openTime2,
    closeTime2,
  ];
}

class ShopStatusState extends Equatable {
  final ShopStatus status;
  final bool canOrder;
  final String? message;
  final bool isWithinSchedule;
  final List<ScheduleSlot> todaySchedule;
  final String? nextOpenTime;
  final bool isLoading;
  final String? error;

  const ShopStatusState({
    this.status = ShopStatus.inactive,
    this.canOrder = false,
    this.message,
    this.isWithinSchedule = false,
    this.todaySchedule = const [],
    this.nextOpenTime,
    this.isLoading = true,
    this.error,
  });

  ShopStatusState copyWith({
    ShopStatus? status,
    bool? canOrder,
    String? message,
    bool? isWithinSchedule,
    List<ScheduleSlot>? todaySchedule,
    String? nextOpenTime,
    bool? isLoading,
    String? error,
  }) {
    return ShopStatusState(
      status: status ?? this.status,
      canOrder: canOrder ?? this.canOrder,
      message: message ?? this.message,
      isWithinSchedule: isWithinSchedule ?? this.isWithinSchedule,
      todaySchedule: todaySchedule ?? this.todaySchedule,
      nextOpenTime: nextOpenTime ?? this.nextOpenTime,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    canOrder,
    message,
    isWithinSchedule,
    todaySchedule,
    nextOpenTime,
    isLoading,
    error,
  ];
}

final shopStatusProvider =
    StateNotifierProvider.family<ShopStatusNotifier, ShopStatusState, String>(
      (ref, locationId) => ShopStatusNotifier(locationId),
    );

class ShopStatusNotifier extends StateNotifier<ShopStatusState> {
  final String locationId;
  Timer? _refreshTimer;

  ShopStatusNotifier(this.locationId) : super(const ShopStatusState()) {
    _init();
  }

  Future<void> _init() async {
    await loadStatus();
    _startPolling();
  }

  Future<void> loadStatus() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'get-shop-status',
        body: {'locationId': locationId},
      );

      if (response.data == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Error al cargar estado del comercio',
        );
        return;
      }

      final data = response.data as Map<String, dynamic>;
      final statusStr = data['status'] as String? ?? 'inactive';

      final status = ShopStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => ShopStatus.inactive,
      );

      final scheduleList =
          (data['todaySchedule'] as List<dynamic>?)
              ?.map((s) => ScheduleSlot.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [];

      state = state.copyWith(
        status: status,
        canOrder: data['canOrder'] as bool? ?? false,
        message: data['message'] as String?,
        isWithinSchedule: data['isWithinSchedule'] as bool? ?? false,
        todaySchedule: scheduleList,
        nextOpenTime: data['nextOpenTime'] as String?,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _startPolling() {
    // Refresh every 30 seconds to check for status changes
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      loadStatus();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

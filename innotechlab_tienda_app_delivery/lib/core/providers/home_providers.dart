// lib/core/providers/home_providers.dart

import 'package:delivery_app_mvvm/data/repositories/home_repository_impl.dart';
import 'package:delivery_app_mvvm/domain/entities/user_status.dart';
import 'package:delivery_app_mvvm/domain/usecases/get_user_online_status.dart';
import 'package:delivery_app_mvvm/domain/usecases/go_offline.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'location_providers.dart';
import 'order_providers.dart';

// ============================================================================
// HOME DATA SOURCES & REPOSITORIES
// ============================================================================

/// Provider para HomeRepositoryImpl
final homeRepositoryProvider = Provider<HomeRepositoryImpl?>((ref) {
  return null; // Placeholder - will be used when needed
});

// ============================================================================
// HOME USE CASES
// ============================================================================

/// Provider para GetUserOnlineStatus
final getUserOnlineStatusProvider = Provider<GetUserOnlineStatus?>((ref) {
  final repo = ref.watch(homeRepositoryProvider);
  if (repo != null) {
    return GetUserOnlineStatus(repo);
  }
  return null;
});

/// Provider para GoOnline
final goOnlineProvider = Provider<GoOnline?>((ref) {
  final repo = ref.watch(homeRepositoryProvider);
  if (repo != null) {
    return GoOnline(repo);
  }
  return null;
});

/// Provider para GoOffline
final goOfflineProvider = Provider<GoOffline?>((ref) {
  final repo = ref.watch(homeRepositoryProvider);
  if (repo != null) {
    return GoOffline(repo);
  }
  return null;
});

// ============================================================================
// HOME STATE
// ============================================================================

/// Estado del HomeNotifier
class HomeState {
  final UserStatus userStatus;
  final bool isLoading;
  final String? errorMessage;
  final double totalEarnings;

  const HomeState({
    required this.userStatus,
    this.isLoading = false,
    this.errorMessage,
    this.totalEarnings = 0.0,
  });

  HomeState copyWith({
    UserStatus? userStatus,
    bool? isLoading,
    String? errorMessage,
    double? totalEarnings,
  }) {
    return HomeState(
      userStatus: userStatus ?? this.userStatus,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      totalEarnings: totalEarnings ?? this.totalEarnings,
    );
  }
}

/// Notifier para manejar el estado de la pantalla principal
class HomeNotifier extends StateNotifier<HomeState> {
  final Ref _ref;
  final SupabaseClient _supabaseClient;

  HomeNotifier(this._ref, this._supabaseClient)
      : super(HomeState(userStatus: UserStatus.offline("You're Offline"))) {
    _initialize();
  }

  void _initialize() {
    // Este provider es de referencia para uso futuro
    // Por ahora, el HomeViewModel existente maneja la lógica
  }

  /// Inicializar el estado online/offline desde el servidor
  Future<void> initializeStatus() async {
    // Placeholder - la lógica real está en HomeViewModel
  }

  /// Poner al repartidor en línea
  Future<void> goOnline() async {
    // Placeholder
  }

  /// Poner al repartidor fuera de línea
  Future<void> goOffline() async {
    // Placeholder
  }

  /// Agregar ganancias
  void addEarnings(double amount) {
    // Placeholder
  }

  void clearError() {
    // Placeholder
  }
}

/// Provider para HomeNotifier
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return HomeNotifier(ref, supabaseClient);
});

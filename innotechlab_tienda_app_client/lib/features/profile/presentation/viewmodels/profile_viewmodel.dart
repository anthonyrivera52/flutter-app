import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? errorMessage;

  const ProfileState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  StreamSubscription<AuthState>? _authSub;

  ProfileNotifier() : super(const ProfileState()) {
    _init();
  }

  void _init() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      state = state.copyWith(user: currentUser, isAuthenticated: true);
    }

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        state = state.copyWith(user: session.user, isAuthenticated: true);
      } else {
        state = const ProfileState();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> updateProfile({String? username, String? avatarUrl}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updates = <String, dynamic>{};
      if (username != null) updates['display_name'] = username;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (updates.isNotEmpty) {
        await Supabase.instance.client.auth
            .updateUser(UserAttributes(data: updates));
      }
      state = state.copyWith(
        isLoading: false,
        user: Supabase.instance.client.auth.currentUser,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<String?> uploadProfileImage(String filePath) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(
            isLoading: false, errorMessage: 'No hay usuario autenticado');
        return null;
      }

      await Supabase.instance.client.storage.from('avatars').uploadBinary(
            '$userId/profile.jpg',
            await File(filePath).readAsBytes(),
            fileOptions: const FileOptions(
                contentType: 'image/jpeg', upsert: true),
          );

      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl('$userId/profile.jpg');

      await Supabase.instance.client.auth
          .updateUser(UserAttributes(data: {'avatar_url': publicUrl}));

      state = state.copyWith(
        isLoading: false,
        user: Supabase.instance.client.auth.currentUser,
      );
      return publicUrl;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await Supabase.instance.client.auth.signOut();
      state = const ProfileState();
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: e.toString(), isAuthenticated: true);
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});

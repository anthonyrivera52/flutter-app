import 'dart:async';
import 'dart:io';
import 'package:flutter_app/data/model/profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authProfileProvider =
    StateNotifierProvider<AuthNotifierProfile, AuthStateProfileModel>(
      (ref) => AuthNotifierProfile(),
    );

class AuthNotifierProfile extends StateNotifier<AuthStateProfileModel> {
  StreamSubscription<AuthState>? _authSubscription;

  AuthNotifierProfile() : super(const AuthStateProfileModel()) {
    _init();
  }

  void _init() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      state = state.copyWith(user: currentUser, isAuthenticated: true);
    }

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      final session = data.session;
      if (session != null) {
        state = state.copyWith(user: session.user, isAuthenticated: true);
      } else {
        state = const AuthStateProfileModel();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> updateUserProfile({String? username, String? avatarUrl}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updates = <String, dynamic>{};
      if (username != null) updates['display_name'] = username;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isNotEmpty) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: updates),
        );
      }

      final currentUser = Supabase.instance.client.auth.currentUser;
      state = state.copyWith(isLoading: false, user: currentUser);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<String?> uploadProfileImage(String filePath) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No hay usuario autenticado',
        );
        return null;
      }

      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            '$userId/profile.jpg',
            await File(filePath).readAsBytes(),
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl('$userId/profile.jpg');

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'avatar_url': publicUrl}),
      );

      final currentUser = Supabase.instance.client.auth.currentUser;
      state = state.copyWith(isLoading: false, user: currentUser);
      return publicUrl;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await Supabase.instance.client.auth.signOut();
      state = const AuthStateProfileModel();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        isAuthenticated: true,
      );
    }
  }

  void clearErrorMessage() {
    state = state.copyWith(errorMessage: null);
  }
}

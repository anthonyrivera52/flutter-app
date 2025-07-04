import 'package:delivery_app_mvvm/core/error/exceptions.dart' as custom_exceptions;
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  Future<AuthUser> signInWithEmailPassword(String email, String password);
  Future<AuthUser> signUpWithEmailPassword(String email, String password);
  Future<void> signOut();
  Session? getCurrentSession();
  Stream<AuthState> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<AuthUser> signInWithEmailPassword(String email, String password) async {
    try {
      final AuthResponse response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw custom_exceptions.AuthException(message: 'Sign-in failed: No user found.');
      }
      return AuthUser(
        id: response.user!.id,
        email: response.user!.email,
        appMetadata: response.user!.appMetadata,
        userMetadata: response.user!.userMetadata,
        aud: response.user!.aud,
        phone: response.user!.phone,
        createdAt: response.user!.createdAt,
        role: response.user!.role,
        updatedAt: response.user!.updatedAt,
      );
    } on AuthException catch (e) {
      print('Supabase Login Error: $e');
      throw custom_exceptions.AuthException(message: e.message);
    } on AuthException catch (e) { // Catch Supabase AuthException
    print('Supabase Login Error: $e');
      throw custom_exceptions.AuthException(message: e.message);
    } catch (e) {
      print('Supabase Login Error: $e');
      throw custom_exceptions.AuthException(message: 'An unexpected error occurred during sign-in: ${e.toString()}');
    }
  }

  @override
  Future<AuthUser> signUpWithEmailPassword(String email, String password) async {
    try {
      final AuthResponse response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw custom_exceptions.AuthException(message: 'Sign-up failed: No user found.');
      }
      // For email confirmation, Supabase usually sends a confirmation email.
      // The user won't be fully authenticated until they confirm.
      // You might want to handle this UI-wise, e.g., show a message to check email.
      return AuthUser(
        id: response.user!.id,
        email: response.user!.email,
        appMetadata: response.user!.appMetadata,
        userMetadata: response.user!.userMetadata,
        aud: response.user!.aud,
        phone: response.user!.phone,
        createdAt: response.user!.createdAt,
        role: response.user!.role,
        updatedAt: response.user!.updatedAt,
      );
    } on AuthException catch (e) {
      throw custom_exceptions.AuthException(message: e.message);
    } on AuthException catch (e) { // Catch Supabase AuthException
      throw custom_exceptions.AuthException(message: e.message);
    } catch (e) {
      throw custom_exceptions.AuthException(message: 'An unexpected error occurred during sign-up: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await supabaseClient.auth.signOut();
    } on AuthException catch (e) {
      throw custom_exceptions.AuthException(message: e.message);
    } catch (e) {
      throw custom_exceptions.AuthException(message: 'An unexpected error occurred during sign-out: ${e.toString()}');
    }
  }

  @override
  Session? getCurrentSession() {
    return supabaseClient.auth.currentSession;
  }

  @override
  Stream<AuthState> get authStateChanges => supabaseClient.auth.onAuthStateChange;
}
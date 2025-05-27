import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mi_tienda/core/errors/exceptions.dart';
import 'package:mi_tienda/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? displayName,
  });
  Future<void> signOut();
  Future<UserModel> getCurrentUser();
  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<UserModel> signIn({required String email, required String password}) async {
    try {
      final AuthResponse response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw ServerException('Inicio de sesión fallido. Usuario no encontrado.');
      }
      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Error inesperado al iniciar sesión: $e');
    }
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final AuthResponse response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

      if (response.user == null) {
        throw ServerException('Registro fallido. No se pudo crear el usuario.');
      }
      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Error inesperado al registrarse: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await supabaseClient.auth.signOut();
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Error inesperado al cerrar sesión: $e');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) {
      throw ServerException('No hay usuario autenticado.');
    }
    return UserModel.fromSupabaseUser(user);
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return supabaseClient.auth.onAuthStateChange.map((event) {
      if (event.event == AuthChangeEvent.signedOut || event.session == null) {
        return null;
      }
      return UserModel.fromSupabaseUser(event.session!.user);
    });
  }
}

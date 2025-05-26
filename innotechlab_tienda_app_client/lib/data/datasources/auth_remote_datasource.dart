import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mi_tienda/core/errors/exceptions.dart';
import 'package:mi_tienda/data/models/user_model.dart';
import 'dart:io'; // Para File en uploadProfileImage

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn(String email, String password);
    Future<UserModel> signUp({ // <-- Añade este método
    required String email,
    required String password,
    String? displayName,
  });
  Future<UserModel?> getCurrentUser(); // Modificado a Future
  Future<void> signOut();
  Future<void> sendOtp(String email);
  Future<UserModel> verifyOtp(String email, String otp);
  Future<UserModel> updateUserProfile({String? username, String? avatarUrl});
  Future<String> uploadProfileImage(String filePath);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl({required this.supabaseClient});

  Future<UserModel> _fetchAndCombineUserProfile(User user) async {
    final response = await supabaseClient.from('profiles').select().eq('id', user.id).single();
    if (response != null) {
      return UserModel.fromSupabaseUser(user, response);
    } else {
      // Si no hay perfil, crear uno básico
      await supabaseClient.from('profiles').insert({
        'id': user.id,
        'email': user.email,
        'username': user.email?.split('@').first,
      });
      return UserModel.fromSupabaseUser(user, {'username': user.email?.split('@').first, 'avatar_url': null});
    }
  }

  @override
  Future<UserModel> signUp({ // <-- Implementa este método
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final AuthResponse response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName}, // Puedes guardar datos adicionales aquí
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
  Future<UserModel> signUp(String email, String password) async {
    try {
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw const AuthException('No se pudo registrar el usuario.');
      }
      // Crear perfil inicial en la tabla 'profiles'
      await supabaseClient.from('profiles').insert({
        'id': response.user!.id,
        'email': response.user!.email,
        'username': response.user!.email?.split('@').first,
      });
      return await _fetchAndCombineUserProfile(response.user!);
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async { // Modificado a Future<UserModel?>
    final user = supabaseClient.auth.currentUser;
    if (user != null) {
      return await _fetchAndCombineUserProfile(user);
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    try {
      await supabaseClient.auth.signOut();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> sendOtp(String email) async {
    try {
      await supabaseClient.auth.signInWithOtp(email: email, shouldCreateUser: false);
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> verifyOtp(String email, String otp) async {
    try {
      final response = await supabaseClient.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );
      if (response.user == null) {
        throw AuthException('OTP inválido o expirado.');
      }
      return await _fetchAndCombineUserProfile(response.user!);
    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> updateUserProfile({String? username, String? avatarUrl}) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw AuthException('Usuario no autenticado.');
      }

      final Map<String, dynamic> updateData = {};
      if (username != null) {
        updateData['username'] = username;
      }
      if (avatarUrl != null) {
        updateData['avatar_url'] = avatarUrl;
      }

      if (updateData.isNotEmpty) {
        // Actualizar la tabla 'profiles'
        await supabaseClient.from('profiles').update(updateData).eq('id', userId);
        // Opcional: Actualizar los metadatos del usuario de Supabase Auth
        // await supabaseClient.auth.updateUser(UserAttributes(
        //   data: {'username': username, 'avatar_url': avatarUrl},
        // ));
      }

      // Obtener el usuario actualizado para reflejar los cambios
      final userAuth = supabaseClient.auth.currentUser;
      if (userAuth == null) {
         throw AuthException('No se pudo obtener el usuario actualizado.');
      }
      return await _fetchAndCombineUserProfile(userAuth);

    } on AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> uploadProfileImage(String filePath) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw AuthException('Usuario no autenticado.');
      }

      final file = File(filePath);
      final fileExtension = file.path.split('.').last;
      final fileName = '$userId.${fileExtension}';

      await supabaseClient.storage.from('avatars').upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final publicUrl = supabaseClient.storage.from('avatars').getPublicUrl(fileName);
      return publicUrl;
    } on StorageException catch (e) {
      throw ServerException('Storage Error: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to upload profile image: $e');
    }
  }
}
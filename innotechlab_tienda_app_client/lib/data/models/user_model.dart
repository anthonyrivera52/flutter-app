// lib/data/models/user_model.dart
import 'package:mi_tienda/domain/entities/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mi_tienda/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
  });

  factory UserModel.fromSupabaseUser(SupabaseUser user) {
    return UserModel(
      id: user.id,
      email: user.email ?? '', // Supabase user email might be null, handle it
      displayName: user.userMetadata?['display_name'] as String?, // Assuming you save displayName in user_metadata
    );
  }

  // Puedes añadir un método toMap si necesitas enviar UserModel a algún lado
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
    };
  }

  // Método para convertir el modelo a la entidad de dominio
  User toEntity() {
    return User(
      id: id,
      email: email,
      displayName: displayName,
    );
  }
}
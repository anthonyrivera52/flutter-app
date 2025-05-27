import 'package:mi_tienda/domain/entities/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
  });

  factory UserModel.fromSupabaseUser(supabase.User user) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      displayName: user.userMetadata?['display_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
    };
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      displayName: displayName,
    );
  }
}

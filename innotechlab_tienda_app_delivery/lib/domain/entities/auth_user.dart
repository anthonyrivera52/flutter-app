// lib/domain/entities/auth_user.dart
import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  final String uid;
  final String? email;
  // Add other user properties you might need from Supabase (e.g., display name, metadata)

  const AuthUser({required this.uid, this.email});

  @override
  List<Object?> get props => [uid, email];
}
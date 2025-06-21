enum UserConnectionStatus { online, offline }

class UserStatus {
  final UserConnectionStatus status;
  final String message;

  UserStatus({required this.status, required this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStatus &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          message == other.message;

  @override
  int get hashCode => status.hashCode ^ message.hashCode;
}
// lib/domain/entities/user_status.dart

enum UserConnectionStatus {
  online,
  offline,
  error, // <-- ¡Asegúrate de que 'error' esté aquí!
}

class UserStatus {
  final UserConnectionStatus status;
  final String message;

  // Constructor base para la clase.
  // Es buena práctica hacerlo privado (UserStatus._) si se usan factory constructors,
  // para forzar que la creación de instancias se haga a través de ellos.
  UserStatus({required this.status, required this.message});

  // Factory constructor para el estado "online"
  factory UserStatus.online(String message) {
    return UserStatus(status: UserConnectionStatus.online, message: message);
  }

  // Factory constructor para el estado "offline"
  factory UserStatus.offline(String message) {
    return UserStatus(status: UserConnectionStatus.offline, message: message);
  }

  // Factory constructor para el estado de "error"
  factory UserStatus.error(String message) {
    return UserStatus(status: UserConnectionStatus.error, message: message);
  }

  // Puedes mantener el constructor público si lo usas en otros lugares,
  // pero para los estados comunes, los factory constructors son más legibles.
  // UserStatus({required this.status, required this.message}); // Descomenta si lo necesitas

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
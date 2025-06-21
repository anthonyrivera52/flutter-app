import '../../domain/entities/user_status.dart';

abstract class HomeLocalDataSource {
  Future<UserStatus> getLastKnownUserStatus();
  Future<void> cacheUserStatus(UserStatus status);
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  UserStatus? _cachedStatus; // Simulating local storage

  @override
  Future<UserStatus> getLastKnownUserStatus() async {
    // In a real app, this would read from SharedPreferences, Hive, etc.
    if (_cachedStatus != null) {
      return _cachedStatus!;
    }
    // Default to offline if no status is cached
    return UserStatus(status: UserConnectionStatus.offline, message: "You're Offline");
  }

  @override
  Future<void> cacheUserStatus(UserStatus status) async {
    _cachedStatus = status;
    // In a real app, this would write to persistent storage
  }
}
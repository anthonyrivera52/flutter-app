import '../../domain/entities/user_status.dart';

abstract class HomeRemoteDataSource {
  Future<UserStatus> fetchUserStatusFromApi();
  Future<UserStatus> sendGoOnlineRequest();
  Future<UserStatus> sendGoOfflineRequest(); // <--- NEW
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  @override
  Future<UserStatus> fetchUserStatusFromApi() async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));
    // In a real app, this would be an http call
    // For now, let's assume it always returns offline for the initial state
    return UserStatus(status: UserConnectionStatus.offline, message: "You're Offline");
  }

  @override
  Future<UserStatus> sendGoOnlineRequest() async {
    // Simulate API call to go online
    await Future.delayed(const Duration(seconds: 2));
    // Assume success for now
    return UserStatus(status: UserConnectionStatus.online, message: "Listening for orders");
  }

  @override
  Future<UserStatus> sendGoOfflineRequest() async { // <--- NEW IMPLEMENTATION
    await Future.delayed(const Duration(seconds: 1));
    // Simulate successful going offline
    return UserStatus(status: UserConnectionStatus.offline, message: "You're Offline");
  }
}
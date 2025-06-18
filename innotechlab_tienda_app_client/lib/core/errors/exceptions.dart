class Exceptions {
  static const String noInternetConnection = 'No Internet Connection';
  static const String serverError = 'Server Error';
  static const String unauthorized = 'Unauthorized';
  static const String notFound = 'Not Found';
  static const String badRequest = 'Bad Request';
  static const String unknownError = 'Unknown Error';
  static const String invalidInput = 'Invalid Input';
  static const String databaseError = 'Database Error';
  static const String fileNotFound = 'File Not Found';
  static const String permissionDenied = 'Permission Denied';
  static const String invalidCredentials = 'Invalid Credentials';
  static const String userNotFound = 'User Not Found';
  static const String emailAlreadyInUse = 'Email Already In Use';
  static const String weakPassword = 'Weak Password';

  Future<void> CacheException(String message) async {
    throw Exception('Cache Error: $message');
  }
  Future<void> ServerException(String message) async {
    throw Exception('Server Error: $message');
  }
  Future<void> AuthException(String message) async {
    throw Exception('Authentication Error: $message');
  }
  Future<void> NetworkException(String message) async {
    throw Exception('Network Error: $message');
  }
  Future<void> ValidationException(String message) async {
    throw Exception('Validation Error: $message');
  }
}
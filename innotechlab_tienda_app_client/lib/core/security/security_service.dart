import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Security Service for handling sensitive data
/// Implements best practices for secure storage and input validation
class SecurityService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

  final FlutterSecureStorage _secureStorage;

  SecurityService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  // ==================== TOKEN MANAGEMENT ====================

  /// Store authentication token securely
  Future<void> storeToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  /// Retrieve authentication token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Store refresh token
  Future<void> storeRefreshToken(String token) async {
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  /// Retrieve refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  /// Store user ID
  Future<void> storeUserId(String userId) async {
    await _secureStorage.write(key: _userIdKey, value: userId);
  }

  /// Retrieve user ID
  Future<String?> getUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }

  /// Clear all auth tokens (logout)
  Future<void> clearAuthData() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userIdKey);
  }

  // ==================== INPUT VALIDATION ====================

  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  /// Validate password strength
  /// Returns null if valid, error message otherwise
  static String? validatePasswordStrength(String password) {
    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'La contraseña debe tener al menos una mayúscula';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'La contraseña debe tener al menos una minúscula';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'La contraseña debe tener al menos un número';
    }
    return null;
  }

  /// Sanitize string input to prevent injection
  static String sanitizeInput(String input) {
    // Remove potential HTML/script tags
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');
    // Remove SQL injection patterns
    sanitized = sanitized.replaceAll(RegExp(r'(\b(SELECT|INSERT|UPDATE|DELETE|DROP|UNION)\b)', caseSensitive: false), '');
    // Trim and limit length
    return sanitized.trim().substring(0, sanitized.trim().length.clamp(0, 500));
  }

  /// Validate phone number format
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s\-()]'), ''));
  }

  // ==================== HASHING ====================

  /// Generate SHA-256 hash of input
  static String sha256Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate HMAC for API request signing
  static String generateHmac(String message, String key) {
    final keyBytes = utf8.encode(key);
    final messageBytes = utf8.encode(message);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(messageBytes);
    return digest.toString();
  }

  // ==================== ENCRYPTION ====================

  /// Generate a secure random token
  static String generateSecureToken([int length = 32]) {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return sha256Hash(random + length.toString()).substring(0, length);
  }

  // ==================== SESSION MANAGEMENT ====================

  /// Check if session is valid based on stored timestamp
  Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivity = prefs.getInt('last_activity_timestamp');

    if (lastActivity == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    const sessionTimeout = 24 * 60 * 60 * 1000; // 24 hours in milliseconds

    return (now - lastActivity) < sessionTimeout;
  }

  /// Update last activity timestamp
  Future<void> updateLastActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_activity_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  // ==================== RATE LIMITING ====================

  /// Check if request should be rate limited
  /// Returns true if too many attempts
  Future<bool> isRateLimited(String action) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'rate_limit_$action';
    final now = DateTime.now().millisecondsSinceEpoch;

    final lastAttempt = prefs.getInt(key);
    if (lastAttempt == null) {
      await prefs.setInt(key, now);
      return false;
    }

    const rateLimitWindow = 60000; // 1 minute
    const maxAttempts = 5;

    final attempts = prefs.getInt('${key}_attempts') ?? 0;

    if (now - lastAttempt > rateLimitWindow) {
      // Reset window
      await prefs.setInt(key, now);
      await prefs.setInt('${key}_attempts', 1);
      return false;
    }

    if (attempts >= maxAttempts) {
      return true;
    }

    await prefs.setInt('${key}_attempts', attempts + 1);
    return false;
  }

  /// Clear rate limit for an action
  Future<void> clearRateLimit(String action) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rate_limit_$action');
    await prefs.remove('${action}_attempts');
  }
}

/// Provider for SecurityService
final securityServiceProvider = SecurityService();

import 'package:meta/meta.dart';

@immutable
abstract class ProjectConstants {
  const ProjectConstants._();

  // ───────────── APPLICATION & SERVER CONSTANTS ─────────────
  static const String appName = 'BaseBackend';
  static const String appVersion = '1.0.0';
  static const String defaultHost = '0.0.0.0';
  static const int defaultPort = 8080;

  // ───────────── RATE LIMIT CONSTANTS ─────────────
  static const int maxRequest = 10;
  static const int maxRequestMin = 10;
  static const Duration rateLimitWindow = Duration(minutes: 1);

  // ───────────── PAGINATION CONSTANTS ─────────────
  static const int defaultPage = 1;
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // ───────────── JWT & AUTH CONSTANTS ─────────────
  static const String jwtIssuer = 'base_backend_api';
  static const String jwtAudience = 'base_backend_clients';
  static const Duration jwtAccessTokenExpiration = Duration(hours: 1);
  static const Duration jwtRefreshTokenExpiration = Duration(days: 30);

  // Context Keys (Shelf Request Context)
  static const String contextUserIdKey = 'userId';
  static const String contextUserRoleKey = 'role';
  static const String contextUserKey = 'user';
  static const String contextJwtTokenKey = 'jwtToken';

  // Header Keys
  static const String headerAuthorization = 'authorization';
  static const String headerBearerPrefix = 'Bearer ';
  static const String headerXRequestId = 'x-request-id';
  static const String headerXForwardedFor = 'x-forwarded-for';

  // Roles
  static const String roleAdmin = 'ADMIN';
  static const String roleUser = 'USER';
  static const String roleManager = 'MANAGER';

  // ───────────── CRYPTO DEFAULT CONSTANTS ─────────────
  static const String passwordPrefix = 'pbkdf2_sha256';
  static const int defaultSaltLength = 16;
  static const int defaultSecureTokenLength = 32;
  static const int defaultKeyLength = 32;
  static const int pbkdf2HashLength = 32;
  static const String jwtEncryptionKey = 'my_super_secret_aes_key_32bytes!';
  // ───────────── ENVIRONMENT BASED CRYPTO CONSTANTS ─────────────
  static const int _debugPbkdf2Iterations = 10000;
  static const int _prodPbkdf2Iterations = 100000;

  /// Çalışma zamanı moduna (Debug/Release) göre dinamik iterasyon sayısı döner
  static int get defaultPbkdf2Iterations {
    bool isDebug = false;
    assert(() {
      isDebug = true;
      return true;
    }());
    return isDebug ? _debugPbkdf2Iterations : _prodPbkdf2Iterations;
  }

  // ───────────── FILE & UPLOAD CONSTANTS ─────────────
  static const int maxFileUploadSizeInBytes = 10 * 1024 * 1024; // 10 MB
  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];
  static const List<String> allowedDocumentExtensions = [
    'pdf',
    'doc',
    'docx',
    'xlsx',
  ];

  // ───────────── CACHE & TIMEOUT CONSTANTS ─────────────
  static const Duration defaultCacheDuration = Duration(minutes: 15);
  static const Duration databaseTimeout = Duration(seconds: 10);
  static const Duration httpClientTimeout = Duration(seconds: 30);

  // ───────────── REGEX PATTERNS ─────────────
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9.\_%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  // ───────────── FAILURE & ERROR MESSAGES ─────────────
  static const FailureMessages failures = FailureMessages._();
}

/// Tüm hata mesajlarını tek noktadan yönetmek için yardımcı grup
@immutable
class FailureMessages {
  const FailureMessages._();

  // Common / General
  final String invalidBody = 'Geçersiz istek gövdesi';
  final String invalidId = 'Geçersiz ID parametresi';
  final String unhandledException = 'Sunucuda beklenmeyen bir hata oluştu.';
  final String fileNotFound = 'İstenen dosya bulunamadı.';

  // Auth & User
  final String invalidPasswordFormat = 'Geçersiz şifre formatı';
  final String invalidEmailFormat = 'Email formatı düzgün değil';
  final String emptyPassword = 'Şifre boş olamaz';
  final String shortPassword = 'Şifre en az 6 karakter olmalıdır.';
  final String userNotFoundOrWrongPassword =
      'Kullanıcı bulunamadı veya şifre hatalı';
  final String userNotFound = 'Kullanıcı bulunamadı';
  final String unauthorizedAccess = 'Bu işlem için yetkiniz bulunmamaktadır.';
  final String tokenGenerationFailed = 'JWT token üretilemedi';
  final String invalidOrExpiredToken = 'Geçersiz veya süresi dolmuş token';

  // Crypto / Hash
  final String emptyHashInput = 'Beklenen hash boş olamaz';
  final String emptyHmacKey = 'HMAC anahtarı boş olamaz';
  final String invalidSaltLength = "Salt uzunluğu 0'dan büyük olmalı";
  final String invalidTokenLength = "Token uzunluğu 0'dan büyük olmalı";
  final String invalidHashFormat = 'Kayıtlı hash formatı geçersiz';

  // Authorization Helper
  String roleRequired(String requiredRole) =>
      'Bu işlem için ($requiredRole) yetkiniz bulunmamaktadır.';
}

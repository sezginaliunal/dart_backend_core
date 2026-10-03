abstract class ProjectConstants {
  const ProjectConstants._();

  // Pagination
  static const int defaultPage = 1;
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Context keys (Shelf request context)
  static const String contextUserIdKey = 'userId';
  static const String contextUserRoleKey = 'role';

  // Header keys
  static const String headerAuthorization = 'authorization';
  static const String headerBearerPrefix = 'Bearer ';

  // Roles
  static const String roleAdmin = 'ADMIN';
  static const String roleUser = 'USER';
  static const String roleManager = 'MANAGER';

  // Crypto
  static const String passwordPrefix = 'pbkdf2_sha256';
  static const int defaultSaltLength = 16;
  static const int defaultSecureTokenLength = 32;
  static const int defaultKeyLength = 32;
  static const int pbkdf2HashLength = 32;
  static const int defaultPbkdf2Iterations = 600000; // env ile ezilir

  // Regex
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static const FailureMessages failures = FailureMessages._();
}

class FailureMessages {
  const FailureMessages._();

  // Common / General
  final String invalidBody = 'Geçersiz istek gövdesi';
  final String invalidId = 'Geçersiz ID parametresi';
  final String unhandledException = 'Sunucuda beklenmeyen bir hata oluştu.';
  final String fileNotFound = 'İstenen dosya bulunamadı.';

  // Auth & User
  final String invalidPasswordFormat =
      'Şifre 8-128 karakter arasında olmalıdır.';
  final String invalidEmailFormat = 'Email formatı düzgün değil';
  final String emptyPassword = 'Şifre boş olamaz';
  final String emailAlreadyExists = 'Bu e-posta zaten kayıtlı.';
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

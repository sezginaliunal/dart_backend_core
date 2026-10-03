import 'dart:io';
import 'package:dotenv/dotenv.dart';

class EnvRepository {
  EnvRepository._internal();
  static final EnvRepository _instance = EnvRepository._internal();
  static EnvRepository get instance => _instance;

  // App & Server
  late final int port;
  late final String env;
  late final bool enableLogs;
  bool get isProd => env == 'prod';

  // DB
  late final String dbUrl;
  late final String dbDbName;
  late final int dbConnectTimeoutSeconds;
  late final int dbMaxRetries;
  late final int dbRetryDelaySeconds;

  // JWT
  late final String jwtSecret;
  late final int jwtAccessTokenExpiryMinutes;
  late final String jwtIssuer;
  late final String jwtAudience;
  late final int jwtRefreshTokenExpiryDays;
  // Crypto
  late final int pbkdf2Iterations;

  // CORS & proxy
  late final List<String> corsAllowedOrigins;
  late final bool trustProxy;

  // Rate limiting
  late final int rateLimitMaxRequests;
  late final int rateLimitWindowSeconds;
  late final int authRateLimitMaxRequests;
  late final int authRateLimitWindowSeconds;

  bool _isInitialized = false;

  /// .env varsa okur, yoksa sadece ortam değişkenlerini kullanır (Docker/Cloud).
  void init({String envPath = '.env'}) {
    if (_isInitialized) return;

    final loader = DotEnv(includePlatformEnvironment: true)
      ..load(File(envPath).existsSync() ? [envPath] : const []);

    String required(String key) {
      final v = loader[key]?.trim();
      if (v == null || v.isEmpty) {
        throw StateError('❌ Kritik Hata: $key tanımlanmamış!');
      }
      return v;
    }

    int intOf(String key, int fallback) =>
        int.tryParse(loader[key] ?? '') ?? fallback;

    bool boolOf(String key, bool fallback) =>
        (loader[key] ?? '$fallback').toLowerCase() == 'true';

    // App & Server
    port = intOf('PORT', 8080);
    env = (loader['ENV'] ?? 'dev').toLowerCase();
    enableLogs = boolOf('ENABLE_LOGS', true);

    // DB
    dbUrl = required('DB_URL');
    dbDbName = loader['DB_DB_NAME'] ?? 'base_backend';
    dbConnectTimeoutSeconds = intOf('DB_CONNECT_TIMEOUT_SECONDS', 10);
    dbMaxRetries = intOf('DB_MAX_RETRIES', 3);
    dbRetryDelaySeconds = intOf('DB_RETRY_DELAY_SECONDS', 2);

    // JWT
    jwtSecret = required('JWT_SECRET');
    jwtAccessTokenExpiryMinutes = intOf('JWT_ACCESS_TOKEN_EXPIRY_MINUTES', 15);
    jwtRefreshTokenExpiryDays = intOf('JWT_REFRESH_TOKEN_EXPIRY_DAYS', 30);
    jwtIssuer = loader['JWT_ISSUER'] ?? 'base_backend_api';
    jwtAudience = loader['JWT_AUDIENCE'] ?? 'base_backend_clients';

    // Crypto
    pbkdf2Iterations = intOf('PBKDF2_ITERATIONS', 600000);

    // CORS & proxy
    corsAllowedOrigins = (loader['CORS_ALLOWED_ORIGINS'] ?? '*')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    trustProxy = boolOf('TRUST_PROXY', false);

    // Rate limiting
    rateLimitMaxRequests = intOf('RATE_LIMIT_MAX_REQUESTS', 100);
    rateLimitWindowSeconds = intOf('RATE_LIMIT_WINDOW_SECONDS', 60);
    authRateLimitMaxRequests = intOf('AUTH_RATE_LIMIT_MAX_REQUESTS', 10);
    authRateLimitWindowSeconds = intOf('AUTH_RATE_LIMIT_WINDOW_SECONDS', 60);

    // Güvenlik doğrulamaları
    if (jwtSecret.length < 32) {
      throw StateError('❌ JWT_SECRET en az 32 karakter olmalı!');
    }
    if (pbkdf2Iterations < 100000) {
      throw StateError('❌ PBKDF2_ITERATIONS en az 100000 olmalı!');
    }
    if (isProd && corsAllowedOrigins.contains('*')) {
      throw StateError("❌ Prod ortamında CORS_ALLOWED_ORIGINS '*' olamaz!");
    }

    _isInitialized = true;
    print('✅ Env yüklendi: [$env modu]');
  }
}

import 'dart:io';
import 'package:dotenv/dotenv.dart';

class EnvRepository {
  // Singleton Pattern
  EnvRepository._internal();
  static final EnvRepository _instance = EnvRepository._internal();
  static EnvRepository get instance => _instance;

  // App & Server
  late final int port;
  late final String env;
  late final bool enableLogs;

  // DB
  late final String dbUrl;
  late final String dbDbName;
  late final int dbConnectTimeoutSeconds;
  late final int dbMaxRetries;
  late final int dbRetryDelaySeconds;

  // JWT
  late final String jwtSecret;
  late final int jwtAccessTokenExpiryMinutes;
  late final int jwtRefreshTokenExpiryDays;
  late final String jwtIssuer;

  // CORS
  late final String corsAllowedOrigins;

  // Rate Limiting
  late final int rateLimitMaxRequests;
  late final int rateLimitWindowSeconds;

  // Logging
  late final String logFilePath;
  late final int logMaxFileSizeMb;
  late final int logMaxBackupFiles;

  bool _isInitialized = false;

  /// .env dosyasını yükleyen ve değişkenleri ayrıştıran metod
  void init({String envPath = '.env'}) {
    if (_isInitialized) return;

    final file = File(envPath);
    if (!file.existsSync()) {
      throw StateError('❌ Kritik Hata: $envPath dosyası bulunamadı!');
    }

    // dotenv paketini başlat
    final envLoader = DotEnv(includePlatformEnvironment: true)..load([envPath]);

    // Zorunlu Alan Kontrolleri
    if (!envLoader.isDefined('DB_URL') || envLoader['DB_URL']!.isEmpty) {
      throw StateError('❌ Kritik Hata: .env içerisinde DB_URL tanımlanmamış!');
    }
    if (!envLoader.isDefined('JWT_SECRET') ||
        envLoader['JWT_SECRET']!.isEmpty) {
      throw StateError(
        '❌ Kritik Hata: .env içerisinde JWT_SECRET tanımlanmamış!',
      );
    }

    // App & Server
    port = int.tryParse(envLoader['PORT'] ?? '') ?? 8080;
    env = envLoader['ENV'] ?? 'dev';
    enableLogs = (envLoader['ENABLE_LOGS'] ?? 'true').toLowerCase() == 'true';

    // DB
    dbUrl = envLoader['DB_URL']!;
    dbDbName = envLoader['DB_DB_NAME'] ?? 'base_backend';
    dbConnectTimeoutSeconds =
        int.tryParse(envLoader['DB_CONNECT_TIMEOUT_SECONDS'] ?? '') ?? 10;
    dbMaxRetries = int.tryParse(envLoader['DB_MAX_RETRIES'] ?? '') ?? 3;
    dbRetryDelaySeconds =
        int.tryParse(envLoader['DB_RETRY_DELAY_SECONDS'] ?? '') ?? 2;

    // JWT
    jwtSecret = envLoader['JWT_SECRET']!;
    jwtAccessTokenExpiryMinutes =
        int.tryParse(envLoader['JWT_ACCESS_TOKEN_EXPIRY_MINUTES'] ?? '') ?? 15;
    jwtRefreshTokenExpiryDays =
        int.tryParse(envLoader['JWT_REFRESH_TOKEN_EXPIRY_DAYS'] ?? '') ?? 7;
    jwtIssuer = envLoader['JWT_ISSUER'] ?? 'base_backend';

    // CORS
    corsAllowedOrigins = envLoader['CORS_ALLOWED_ORIGINS'] ?? '*';

    // Rate Limiting
    rateLimitMaxRequests =
        int.tryParse(envLoader['RATE_LIMIT_MAX_REQUESTS'] ?? '') ?? 100;
    rateLimitWindowSeconds =
        int.tryParse(envLoader['RATE_LIMIT_WINDOW_SECONDS'] ?? '') ?? 60;

    // Logging
    logFilePath = envLoader['LOG_FILE_PATH'] ?? 'logs/app.log';
    logMaxFileSizeMb =
        int.tryParse(envLoader['LOG_MAX_FILE_SIZE_MB'] ?? '') ?? 5;
    logMaxBackupFiles =
        int.tryParse(envLoader['LOG_MAX_BACKUP_FILES'] ?? '') ?? 5;

    _isInitialized = true;
    print('✅ EnvRepository [dotenv] ile başarıyla yüklendi: [$env modu]');
  }
}

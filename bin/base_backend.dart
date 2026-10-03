import 'dart:async';
import 'dart:io';
import 'package:base_backend/core/env/env_repository.dart';
import 'package:base_backend/core/middlewares/cors_middleware.dart';
import 'package:base_backend/core/middlewares/error_middleware.dart';
import 'package:base_backend/core/middlewares/rate_middleware.dart';
import 'package:base_backend/core/router/router.dart';
import 'package:base_backend/core/services/mongo/mongo_repository.dart';
import 'package:base_backend/modules/auth/auth_router.dart';
import 'package:base_backend/modules/users/users_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

Future<void> main(List<String> args) async {
  final env = EnvRepository.instance;

  try {
    env.init();
  } catch (e) {
    stderr.writeln(e);
    exit(1);
  }

  try {
    await _connectWithRetry(env);
  } catch (e) {
    stderr.writeln('❌ MongoDB bağlantısı kurulamadı: $e');
    exit(1);
  }

  // E-posta tekilliği DB seviyesinde garanti edilir
  await _ensureIndexes();

  final apiRouter = ApiRouter(
    modules: [
      UsersRouter(),
      AuthRouter(),
      // Yeni modüller buraya: ProductsRouter(), OrdersRouter() ...
    ],
  );

  var pipeline = const Pipeline();
  if (env.enableLogs) {
    pipeline = pipeline.addMiddleware(logRequests());
  }

  final handler = pipeline
      .addMiddleware(corsMiddleware(allowedOrigins: env.corsAllowedOrigins))
      .addMiddleware(errorHandlerMiddleware())
      .addMiddleware(
        rateLimitMiddleware(
          maxRequests: env.rateLimitMaxRequests,
          windowSize: Duration(seconds: env.rateLimitWindowSeconds),
          trustProxy: env.trustProxy,
        ),
      )
      .addHandler(apiRouter.handler);

  final server = await io.serve(handler, InternetAddress.anyIPv4, env.port);
  print('🚀 Server ayakta: http://${server.address.host}:${server.port}');

  // Graceful shutdown
  Future<void> shutdown(ProcessSignal signal) async {
    print('⏹ $signal alındı, kapatılıyor...');
    await server.close(force: true);
    await MongoDatabase.instance.close();
    exit(0);
  }

  // SIGINT (Ctrl+C) her platformda çalışır; SIGTERM Windows'ta desteklenmez.
  // Hata stream'e asenkron düştüğü için try/catch yerine onError kullanılır.
  ProcessSignal.sigint.watch().listen(shutdown, onError: (_) {});
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen(shutdown, onError: (_) {});
  }
}

Future<void> _connectWithRetry(EnvRepository env) async {
  for (var attempt = 1; ; attempt++) {
    try {
      await MongoDatabase.instance
          .connect(env.dbUrl, dbName: env.dbDbName)
          .timeout(Duration(seconds: env.dbConnectTimeoutSeconds));
      return;
    } catch (e) {
      if (attempt >= env.dbMaxRetries) rethrow;
      stderr.writeln(
        '⚠️ DB bağlantı denemesi $attempt başarısız, tekrar denenecek...',
      );
      await Future.delayed(Duration(seconds: env.dbRetryDelaySeconds));
    }
  }
}

/// Index'ler: e-posta/token tekilliği DB seviyesinde garanti edilir.
Future<void> _ensureIndexes() async {
  final db = MongoDatabase.instance;

  Future<void> ensure(
    String collection,
    Map<String, dynamic> keys, {
    bool unique = false,
  }) async {
    try {
      await db.collection(collection).createIndex(keys: keys, unique: unique);
    } catch (e) {
      stderr.writeln('⚠️ $collection index oluşturulamadı ($keys): $e');
    }
  }

  await ensure('users', {'email': 1}, unique: true);
  await ensure('refresh_tokens', {'tokenHash': 1}, unique: true);
  await ensure('refresh_tokens', {'familyId': 1});
  await ensure('refresh_tokens', {'userId': 1});
}

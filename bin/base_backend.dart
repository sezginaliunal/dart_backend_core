import 'dart:io';
import 'package:base_backend/core/constants/project_constants.dart';
import 'package:base_backend/core/env/env_repository.dart';
import 'package:base_backend/core/middlewares/cors_middleware.dart';
import 'package:base_backend/core/middlewares/json_content_type_middleware.dart';
import 'package:base_backend/core/middlewares/rate_middleware.dart';
import 'package:base_backend/core/router/router.dart';
import 'package:base_backend/core/services/mongo/mongo_repository.dart';
import 'package:base_backend/modules/auth/auth_router.dart';
import 'package:base_backend/modules/users/users_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

void main(List<String> args) async {
  try {
    // 1. Singleton yapısını başlat
    EnvRepository.instance.init();
  } catch (e) {
    return;
  }

  final env = EnvRepository.instance;
  await MongoDatabase.instance.connect(env.dbUrl);
  final apiRouter = ApiRouter(
    modules: [
      UsersRouter(),
      AuthRouter(),
      // Yeni modüller buraya: ProductsRouter(), OrdersRouter() ...
    ],
  );

  // 3. Dynamic Pipeline Kurulumu
  var pipeline = const Pipeline();

  // .env dosyasında ENABLE_LOGS=true ise Shelf'in logRequests middleware'ini ekler
  if (env.enableLogs) {
    pipeline = pipeline.addMiddleware(logRequests());
  }

  // Diğer Middleware'leri sırasıyla ekle
  final handler = pipeline
      .addMiddleware(corsMiddleware())
      .addMiddleware(
        rateLimitMiddleware(
          maxRequests: ProjectConstants.maxRequest,
          windowSize: Duration(minutes: ProjectConstants.maxRequestMin),
        ),
      )
      .addMiddleware(jsonContentTypeMiddleware())
      .addHandler(apiRouter.handler);

  // 4. EnvRepository içerisindeki portu kullanarak sunucuyu başlat (İsteğe bağlı IP dinamikleştirilebilir)
  final server = await io.serve(handler, InternetAddress.anyIPv4, env.port);

  print(
    '🚀 Server başarıyla ayakta: http://${server.address.host}:${server.port}',
  );
}

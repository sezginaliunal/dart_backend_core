import 'dart:io';
import 'package:base_backend/core/middlewares/cors_middleware.dart';
import 'package:base_backend/core/middlewares/json_content_type_middleware.dart';
import 'package:base_backend/core/router/router.dart';
import 'package:base_backend/modules/products/products_router.dart';
import 'package:base_backend/modules/users/users_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

void main(List<String> args) async {
  final apiRouter = ApiRouter(
    modules: [
      UsersRouter(),
      ProductsRouter(),
      // Yeni modüller buraya: ProductsRouter(), OrdersRouter() ...
    ],
  );

  // Middleware Pipeline
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsMiddleware())
      .addMiddleware(jsonContentTypeMiddleware())
      .addHandler(apiRouter.handler);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);

  print(
    '🚀 Server başarıyla ayakta: http://${server.address.host}:${server.port}',
  );
}

import 'package:base_backend/core/module/app_module.dart';
import 'package:base_backend/core/result/result.dart';
import 'package:base_backend/core/result/result_shelf_extension.dart';
import 'package:base_backend/core/services/mongo/mongo_repository.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class ApiRouter {
  ApiRouter({required List<AppModule> modules}) {
    _setupRoutes(modules);
  }

  final Router _rootRouter = Router(
    notFoundHandler: (Request request) {
      return Result<Never>.failure(
        NotFoundFailure('Route bulunamadı: ${request.requestedUri.path}'),
      ).toResponse();
    },
  );

  Handler get handler => _rootRouter.call;

  void _setupRoutes(List<AppModule> modules) {
    // Health Check Endpoint
    _rootRouter.get('/health', (Request request) {
      return Result.success({
        'status': 'UP',
        'db': MongoDatabase.instance.isConnected,
        'timestamp': DateTime.now().toIso8601String(),
      }).toResponse();
    });

    // Modül Mount İşlemleri
    for (final module in modules) {
      _rootRouter.mount(module.path, module.handler);
    }
  }
}

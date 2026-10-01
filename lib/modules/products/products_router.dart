import 'package:base_backend/core/middlewares/auth_middleware.dart';
import 'package:base_backend/core/module/app_module.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'products_controller.dart';
import 'products_repository.dart';
import 'products_service.dart';

class ProductsRouter implements AppModule {
  ProductsRouter()
      : _controller = ProductsController(ProductsService(ProductsRepository()));

  final ProductsController _controller;

  @override
  String get path => '/api/v1/products';

  Router get _internalRouter {
    final router = Router();

    // Koleksiyon
    router.get('/', _controller.findAll);
    router.post('/', _controller.create);

    // ⚠️ Bulk rotaları '/<id>' rotalarından ÖNCE tanımlanmalı,
    // aksi halde "bulk" bir id olarak yakalanır.
    router.post('/bulk', _controller.bulkCreate);
    router.put('/bulk', _controller.bulkUpdate);
    router.delete('/bulk', _controller.bulkDelete);

    // Tekil kayıt
    router.get('/<id>', _controller.getById);
    router.put('/<id>', _controller.update);
    router.delete('/<id>', _controller.deleteById);

    return router;
  }

  @override
  Handler get handler {
    return Pipeline()
        .addMiddleware(authMiddleware())
        .addHandler(_internalRouter.call);
  }
}

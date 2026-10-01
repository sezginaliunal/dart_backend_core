import 'package:base_backend/core/middlewares/auth_middleware.dart';
import 'package:base_backend/core/module/app_module.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'users_controller.dart';
import 'users_repository.dart';
import 'users_service.dart';

class UsersRouter implements AppModule {
  UsersRouter()
    : _controller = UsersController(UsersService(UsersRepository()));

  final UsersController _controller;

  @override
  String get path => '/api/v1/users';

  Router get _internalRouter {
    final router = Router();

    router.get('/', _controller.findAll);
    router.get('/<id>', _controller.getById);
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

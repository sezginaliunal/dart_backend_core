import 'package:base_backend/core/module/app_module.dart';
import 'package:base_backend/core/services/auth/jwt_repository.dart';
import 'package:base_backend/core/services/crypto/crypto_repository.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'auth_controller.dart';
import 'auth_repository.dart';
import 'auth_service.dart';

class AuthRouter implements AppModule {
  AuthRouter()
    : _controller = AuthController(
        AuthService(
          repository: AuthRepository(),
          jwtRepository: JwtRepository.instance,
          cryptoRepository: CryptoRepository(),
        ),
      );

  final AuthController _controller;

  @override
  String get path => '/api/v1/auth';

  Router get _internalRouter {
    final router = Router();

    // Koleksiyon
    router.post('/register', _controller.register);
    router.post('/login', _controller.login);

    return router;
  }

  @override
  Handler get handler {
    return Pipeline()
    // .addMiddleware(authMiddleware())
    .addHandler(_internalRouter.call);
  }
}

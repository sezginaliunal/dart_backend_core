import 'package:base_backend/core/env/env_repository.dart';
import 'package:base_backend/core/middlewares/rate_middleware.dart';
import 'package:base_backend/core/module/app_module.dart';
import 'package:base_backend/core/services/auth/jwt_repository.dart';
import 'package:base_backend/core/services/crypto/isolate_crypto_repository.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'auth_controller.dart';
import 'auth_repository.dart';
import 'auth_service.dart';
import 'refresh_token_repository.dart';

class AuthRouter implements AppModule {
  AuthRouter()
    : _controller = AuthController(
        AuthService(
          repository: AuthRepository(),
          refreshTokenRepository: RefreshTokenRepository(),
          jwtRepository: JwtRepository.instance,
          cryptoRepository: const IsolateCryptoRepository(),
          pbkdf2Iterations: EnvRepository.instance.pbkdf2Iterations,
          accessTokenMinutes:
              EnvRepository.instance.jwtAccessTokenExpiryMinutes,
          refreshTokenDays: EnvRepository.instance.jwtRefreshTokenExpiryDays,
        ),
      );

  final AuthController _controller;

  @override
  String get path => '/api/v1/auth';

  Router get _internalRouter {
    final router = Router();

    router.post('/register', _controller.register);
    router.post('/login', _controller.login);
    router.post('/refresh', _controller.refresh);
    router.post('/logout', _controller.logout);

    return router;
  }

  @override
  Handler get handler {
    final env = EnvRepository.instance;
    return Pipeline()
        // Brute-force koruması: genel limitten ayrı ve daha sıkı
        .addMiddleware(
          rateLimitMiddleware(
            maxRequests: env.authRateLimitMaxRequests,
            windowSize: Duration(seconds: env.authRateLimitWindowSeconds),
            trustProxy: env.trustProxy,
          ),
        )
        .addHandler(_internalRouter.call);
  }
}

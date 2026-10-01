import 'package:base_backend/core/result/result.dart';
import 'package:base_backend/core/result/result_shelf_extension.dart';
import 'package:base_backend/core/services/auth/jwt_repository.dart';
import 'package:shelf/shelf.dart';

Middleware authMiddleware() {
  final jwtRepository = JwtRepository.instance;

  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['authorization'];

      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Result<Never>.failure(
          UnauthorizedFailure('Yetkisiz erişim: Token bulunamadı'),
        ).toResponse();
      }

      final token = authHeader.substring(7);
      final decodedToken = jwtRepository.verify(token);

      return decodedToken.fold(
        onFailure: (failure) {
          return Result<Never>.failure(failure).toResponse();
        },
        onSuccess: (data) async {
          final payload = data.payload;
          final userRole = payload["issuer"];
          final userId = payload["id"];

          final updatedRequest = request.change(
            context: {'userId': userId, 'role': userRole},
          );

          return await innerHandler(updatedRequest);
        },
      );
    };
  };
}

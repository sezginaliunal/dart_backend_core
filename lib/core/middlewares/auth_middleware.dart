import 'package:base_backend/core/constants/project_constants.dart';
import 'package:base_backend/core/result/result.dart';
import 'package:base_backend/core/result/result_shelf_extension.dart';
import 'package:base_backend/core/services/auth/jwt_repository.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';

Middleware authMiddleware({IJwtRepository? jwtRepository}) {
  final jwtRepo = jwtRepository ?? JwtRepository.instance;

  Response unauthorized() => Result<Never>.failure(
    UnauthorizedFailure(ProjectConstants.failures.unauthorizedAccess),
  ).toResponse();

  return (Handler inner) {
    return (Request request) async {
      final authHeader = request.headers[ProjectConstants.headerAuthorization];
      if (authHeader == null ||
          !authHeader.startsWith(ProjectConstants.headerBearerPrefix)) {
        return unauthorized();
      }

      final token = authHeader
          .substring(ProjectConstants.headerBearerPrefix.length)
          .trim();

      final result = jwtRepo.verify(token);
      if (result is FailureResult<JWT>) {
        return Result<Never>.failure(result.failure).toResponse();
      }
      final payload = (result as Success<JWT>).data.payload;

      if (payload is! Map) return unauthorized();
      final userId = payload['id'];
      final role = payload['role'];
      if (userId is! String || role is! String) return unauthorized();

      return inner(
        request.change(
          context: {
            ProjectConstants.contextUserIdKey: userId,
            ProjectConstants.contextUserRoleKey: role,
          },
        ),
      );
    };
  };
}

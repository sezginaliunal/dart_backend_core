import 'package:base_backend/core/constants/project_constants.dart';
import 'package:base_backend/core/result/result.dart';
import 'package:base_backend/core/result/result_shelf_extension.dart';
import 'package:shelf/shelf.dart';

/// Belirtilen rolün yetkisini kontrol eden Middleware.
Middleware requireRoleMiddleware(String requiredRole) {
  return (Handler innerHandler) {
    return (Request request) async {
      final userRole =
          request.context[ProjectConstants.contextUserRoleKey] as String?;

      if (userRole == null || userRole != requiredRole) {
        return Result<Never>.failure(
          ValidationFailure(
            ProjectConstants.failures.roleRequired(requiredRole),
          ),
        ).toResponse();
      }

      return await innerHandler(request);
    };
  };
}

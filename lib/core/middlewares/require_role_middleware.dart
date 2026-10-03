import 'package:base_backend/core/constants/project_constants.dart';
import 'package:base_backend/core/result/result.dart';
import 'package:base_backend/core/result/result_shelf_extension.dart';
import 'package:shelf/shelf.dart';

Middleware requireRoleMiddleware(String requiredRole) {
  return (Handler inner) {
    return (Request request) async {
      final userRole =
          request.context[ProjectConstants.contextUserRoleKey] as String?;

      if (userRole != requiredRole) {
        return Result<Never>.failure(
          ForbiddenFailure(ProjectConstants.failures.roleRequired(requiredRole)),
        ).toResponse();
      }
      return inner(request);
    };
  };
}

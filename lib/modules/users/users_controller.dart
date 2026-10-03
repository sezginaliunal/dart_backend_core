import 'package:base_backend/core/constants/project_constants.dart';
import 'package:base_backend/core/mixins/controller_helpers.dart';
import 'package:base_backend/core/result/result_shelf_extension.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'users_service.dart';

class UsersController with ControllerHelpers {
  final UsersService _service;

  UsersController(this._service);

  Future<Response> getById(Request request, String id) async {
    // Sadece ADMIN veya kullanıcının kendisi
    if (!isAdmin(request) && currentUserId(request) != id) {
      return forbidden(ProjectConstants.failures.unauthorizedAccess);
    }
    final result = await _service.getById(id);
    return result.toResponse();
  }

  /// Sadece ADMIN (router'da requireRole ile korunuyor). ?page=1&pageSize=20
  Future<Response> findAll(Request request) async {
    final q = request.url.queryParameters;
    final page = (int.tryParse(q['page'] ?? '') ?? ProjectConstants.defaultPage)
        .clamp(1, 1000000)
        .toInt();
    final size =
        (int.tryParse(q['pageSize'] ?? '') ?? ProjectConstants.defaultPageSize)
            .clamp(1, ProjectConstants.maxPageSize)
            .toInt();

    final result = await _service.findAll(skip: (page - 1) * size, limit: size);
    return result.toResponse();
  }

  Future<Response> deleteById(Request request) async {
    final targetId = request.params['id'];
    if (targetId == null) return invalidBody();

    // Kullanıcı ADMIN değilse VE kendi ID'sini silmeye çalışmıyorsa engelle
    if (!isAdmin(request) && currentUserId(request) != targetId) {
      return forbidden(
        'Sadece kendi hesabınızı veya ADMIN olarak bu hesabı silebilirsiniz.',
      );
    }

    final result = await _service.deleteById(targetId);
    return result.toResponse();
  }
}

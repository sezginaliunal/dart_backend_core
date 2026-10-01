import 'package:base_backend/core/result/result.dart';
import 'package:base_backend/core/result/result_shelf_extension.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'users_service.dart';

class UsersController {
  final UsersService _service;

  UsersController(this._service);

  Future<Response> getById(Request request, String id) async {
    final result = await _service.getById(id);
    return result
        .toResponse(); // 👈 Hatalı switch bloğu toResponse() ile değiştirildi
  }

  Future<Response> findAll(Request request) async {
    final result = await _service.findAll();
    return result
        .toResponse(); // 👈 Hatalı switch bloğu toResponse() ile değiştirildi
  }

  Future<Response> deleteById(Request request) async {
    final targetId = request.params['id'];
    final currentUserId = request.context['userId'] as String?;
    final currentUserRole = request.context['role'] as String?;

    // Kullanıcı ADMIN değilse VE kendi ID'sini silmeye çalışmıyorsa engelle
    final isAdmin = currentUserRole == 'ADMIN';
    final isSelf = currentUserId == targetId;

    if (!isAdmin && !isSelf) {
      return Result<Never>.failure(
        UnauthorizedFailure(
          'Sadece kendi hesabınızı veya ADMIN olarak bu hesabı silebilirsiniz.',
        ),
      ).toResponse();
    }

    // İşleme devam et
    final result = await _service.deleteById(targetId!);
    return result.toResponse();
  }
}

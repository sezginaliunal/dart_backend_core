import 'package:base_backend/core/result/result.dart';
import 'package:base_backend/core/result/result_shelf_extension.dart';
import 'package:shelf/shelf.dart';

/// Belirtilen rolün veya rollerin yetkisini kontrol eden Middleware.
///
/// Not: Bu middleware'den önce `authMiddleware`'in çalışmış ve
/// `request.context['user']` veya `request.context['role']` verisini doldurmuş olması gerekir.
Middleware requireRoleMiddleware(String requiredRole) {
  return (Handler innerHandler) {
    return (Request request) async {
      // 1. Auth middleware tarafından context'e eklenen kullanıcı rolünü alıyoruz
      final userRole = request.context['role'] as String?;

      // Alternatif: Eğer kullanıcı objesi map/class olarak eklendiyse:
      // final user = request.context['user'] as Map<String, dynamic>?;
      // final userRole = user?['role'] as String?;

      // 2. Rol bilgisi yoksa veya eşleşmiyorsa yetkisiz erişim hatası dön
      if (userRole == null || userRole != requiredRole) {
        return Result<Never>.failure(
          ValidationFailure(
            'Bu işlem için ($requiredRole) yetkiniz bulunmamaktadır.',
          ),
        ).toResponse();
      }

      // 3. Yetki sağlandıysa isteği bir sonraki handler'a ilet
      return await innerHandler(request);
    };
  };
}

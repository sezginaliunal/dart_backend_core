import 'package:base_backend/core/constants/project_constants.dart';
import 'package:base_backend/core/result/result.dart';
import 'package:base_backend/core/result/result_shelf_extension.dart';
import 'package:base_backend/core/services/auth/jwt_repository.dart';
import 'package:base_backend/core/services/crypto/crypto_repository.dart';
import 'package:shelf/shelf.dart';

Middleware authMiddleware({ICryptoRepository? cryptoRepository}) {
  final jwtRepository = JwtRepository.instance;
  final crypto = cryptoRepository ?? CryptoRepository();

  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers[ProjectConstants.headerAuthorization];

      if (authHeader == null ||
          !authHeader.startsWith(ProjectConstants.headerBearerPrefix)) {
        return Result<Never>.failure(
          UnauthorizedFailure(ProjectConstants.failures.unauthorizedAccess),
        ).toResponse();
      }

      // 1. Header'dan şifreli token'ı al
      final encryptedToken = authHeader.substring(
        ProjectConstants.headerBearerPrefix.length,
      );

      // 2. Şifrelenmiş token'ı geri çöz (Decrypt)
      final decryptResult = crypto.decrypt(
        encryptedToken,
        ProjectConstants.jwtEncryptionKey,
      );

      return decryptResult.fold(
        onFailure: (failure) {
          return Result<Never>.failure(
            UnauthorizedFailure('Geçersiz veya bozulmuş erişim jetonu.'),
          ).toResponse();
        },
        onSuccess: (rawJwtToken) {
          // 3. Çözülen Orijinal JWT'yi doğrula
          final decodedToken = jwtRepository.verify(rawJwtToken);

          return decodedToken.fold(
            onFailure: (failure) {
              return Result<Never>.failure(failure).toResponse();
            },
            onSuccess: (data) async {
              final payload = data.payload;
              final userRole = payload["issuer"];
              final userId = payload["id"];

              final updatedRequest = request.change(
                context: {
                  ProjectConstants.contextUserIdKey: userId,
                  ProjectConstants.contextUserRoleKey: userRole,
                },
              );

              return await innerHandler(updatedRequest);
            },
          );
        },
      );
    };
  };
}

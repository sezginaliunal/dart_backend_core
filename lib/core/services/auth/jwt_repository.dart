import 'package:base_backend/core/constants/project_constants.dart';
import 'package:base_backend/core/env/env_repository.dart';
import 'package:base_backend/core/result/result.dart';
import 'package:base_backend/core/services/auth/models/jwt_payload.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

abstract interface class IJwtRepository {
  Result<String> generateToken(JwtPayload payload);
  Result<JWT> verify(String token);
}

class JwtRepository implements IJwtRepository {
  static JwtRepository? _instance;
  JwtRepository._();
  static JwtRepository get instance => _instance ??= JwtRepository._();

  @override
  Result<JWT> verify(String token) {
    final env = EnvRepository.instance;
    try {
      return Success(
        JWT.verify(
          token,
          SecretKey(env.jwtSecret),
          issuer: env.jwtIssuer,
          audience: Audience.one(env.jwtAudience),
        ),
      );
    } catch (_) {
      // Süresi dolmuş, imzası bozuk, issuer uyuşmayan hepsi aynı cevap
      return FailureResult(
        JwtFailure(ProjectConstants.failures.invalidOrExpiredToken),
      );
    }
  }

  @override
  Result<String> generateToken(JwtPayload payload) {
    final env = EnvRepository.instance;
    try {
      final jwt = JWT(
        payload.toJson(),
        issuer: env.jwtIssuer,
        audience: Audience.one(env.jwtAudience),
        subject: payload.id,
      );
      final token = jwt.sign(
        SecretKey(env.jwtSecret),
        expiresIn: Duration(minutes: env.jwtAccessTokenExpiryMinutes),
      );
      return Success(token);
    } catch (e) {
      return FailureResult(NotGenerateJwtFailure(e.toString()));
    }
  }
}

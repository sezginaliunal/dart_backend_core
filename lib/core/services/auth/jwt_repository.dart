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
  // Avoid self instance
  JwtRepository._();
  static JwtRepository get instance => _instance ??= JwtRepository._();

  @override
  Result<JWT> verify(String token) {
    try {
      // Verify a token (SecretKey for HMAC & PublicKey for all the others)
      return Success(JWT.verify(token, SecretKey('secret passphrase')));
    } on JWTExpiredException {
      return FailureResult(JwtFailure('Jwt Expired'));
    } on JWTException catch (ex) {
      return FailureResult(JwtFailure(ex.message));
    }
  }

  @override
  Result<String> generateToken(JwtPayload payload) {
    try {
      // Generate a JSON Web Token
      // You can provide the payload as a key-value map or a string
      final jwt = JWT(payload.toJson(), issuer: payload.issuer);

      // Sign it (default with HS256 algorithm)
      final token = jwt.sign(
        expiresIn: Duration(
          minutes: EnvRepository.instance.jwtAccessTokenExpiryMinutes,
        ),
        SecretKey('secret passphrase'),
      );

      return Success(token);
    } catch (e) {
      return FailureResult(NotGenerateJwtFailure(e.toString()));
    }
  }
}

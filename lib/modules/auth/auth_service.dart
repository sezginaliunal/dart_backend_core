import 'package:base_backend/core/constants/project_constants.dart';
import 'package:base_backend/core/extensions/null_or_empty.dart';
import 'package:base_backend/core/extensions/validation.dart';
import 'package:base_backend/core/result/result.dart';
import 'package:base_backend/core/services/auth/jwt_repository.dart';
import 'package:base_backend/core/services/auth/models/jwt_payload.dart';
import 'package:base_backend/core/services/crypto/crypto_repository.dart';
import 'package:base_backend/modules/auth/auth_repository.dart';
import 'package:base_backend/modules/auth/models/login_payload.dart';
import 'package:base_backend/modules/auth/models/login_response.dart';
import 'package:base_backend/modules/auth/models/register_payload.dart';

class AuthService {
  final IAuthRepository _repository;
  final IJwtRepository _jwtRepository;
  final ICryptoRepository _cryptoRepository;

  AuthService({
    required IAuthRepository repository,
    required IJwtRepository jwtRepository,
    required ICryptoRepository cryptoRepository,
  }) : _repository = repository,
       _jwtRepository = jwtRepository,
       _cryptoRepository = cryptoRepository;

  // ───────────── REGISTER (Şifre Hash'leme) ─────────────

  Future<Result<RegisterPayload>> register(RegisterPayload payload) async {
    // 1. Validation
    if (payload.password.isNullOrEmpty || !payload.password.isValidPassword) {
      return Result.failure(
        ValidationFailure(ProjectConstants.failures.invalidPasswordFormat),
      );
    }

    // 2. Şifreyi Hash'le
    final hashResult = _cryptoRepository.hashPassword(payload.password);

    return hashResult.fold(
      onFailure: (failure) => FailureResult(failure),
      onSuccess: (hashedPassword) async {
        final securePayload = payload.copyWith(password: hashedPassword);
        return await _repository.register(securePayload);
      },
    );
  }

  // ───────────── LOGIN (Şifre Doğrulama) ─────────────

  Future<Result<LoginResponse>> login(LoginPayload payload) async {
    // 1. Validation
    if (payload.email.isNullOrEmpty || !payload.email.isValidEmail) {
      return Result.failure(
        ValidationFailure(ProjectConstants.failures.invalidEmailFormat),
      );
    }
    if (payload.password.isNullOrEmpty) {
      return Result.failure(
        ValidationFailure(ProjectConstants.failures.emptyPassword),
      );
    }
    if (!payload.password.isValidPassword) {
      return Result.failure(
        ValidationFailure(ProjectConstants.failures.shortPassword),
      );
    }

    // 2. Kullanıcıyı DB'den Getir
    final userResult = await _repository.findUserByEmail(payload.email);

    return userResult.fold(
      onFailure: (failure) => FailureResult(failure),
      onSuccess: (user) {
        if (user == null) {
          return Result.failure(
            UnauthorizedFailure(
              ProjectConstants.failures.userNotFoundOrWrongPassword,
            ),
          );
        }

        // 3. Şifreyi Doğrula
        final verifyResult = _cryptoRepository.verifyPassword(
          payload.password,
          user.passwordHash,
        );

        return verifyResult.fold(
          onFailure: (failure) => FailureResult(failure),
          onSuccess: (isMatched) {
            if (!isMatched) {
              return Result.failure(
                UnauthorizedFailure(
                  ProjectConstants.failures.userNotFoundOrWrongPassword,
                ),
              );
            }

            // 4. Şifre Doğru -> JWT Üret
            final jwtPayload = JwtPayload(
              id: user.id,
              issuer: ProjectConstants.jwtIssuer,
            );
            final generatedJwt = _jwtRepository.generateToken(jwtPayload);
            return generatedJwt.fold(
              onFailure: (failure) =>
                  FailureResult(NotGenerateJwtFailure(failure.message)),
              onSuccess: (rawJwt) {
                // JWT Token'ı AES ile şifreliyoruz
                final encryptedJwtResult = _cryptoRepository.encrypt(
                  rawJwt,
                  ProjectConstants
                      .jwtEncryptionKey, // Proje sabitlerinize eklenecek gizli anahtar
                );

                return encryptedJwtResult.fold(
                  onFailure: (failure) => FailureResult(failure),
                  onSuccess: (encryptedToken) => Result.success(
                    LoginResponse(accessToken: encryptedToken),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

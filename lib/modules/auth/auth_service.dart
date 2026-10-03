import 'dart:convert';
import 'dart:math';
import 'package:base_backend/core/constants/project_constants.dart';
import 'package:base_backend/core/extensions/validation.dart';
import 'package:base_backend/core/result/result.dart';
import 'package:base_backend/core/services/auth/jwt_repository.dart';
import 'package:base_backend/core/services/auth/models/jwt_payload.dart';
import 'package:base_backend/core/services/crypto/isolate_crypto_repository.dart';
import 'package:base_backend/modules/auth/auth_repository.dart';
import 'package:base_backend/modules/auth/models/auth_user_dto.dart';
import 'package:base_backend/modules/auth/models/login_payload.dart';
import 'package:base_backend/modules/auth/models/login_response.dart';
import 'package:base_backend/modules/auth/models/refresh_payload.dart';
import 'package:base_backend/modules/auth/models/refresh_token_record.dart';
import 'package:base_backend/modules/auth/models/register_payload.dart';
import 'package:base_backend/modules/auth/refresh_token_repository.dart';
import 'package:crypto/crypto.dart';

class AuthService {
  AuthService({
    required IAuthRepository repository,
    required IRefreshTokenRepository refreshTokenRepository,
    required IJwtRepository jwtRepository,
    required IIsolateCryptoRepository cryptoRepository,
    required int pbkdf2Iterations,
    required int accessTokenMinutes,
    required int refreshTokenDays,
  }) : _repository = repository,
       _refreshRepository = refreshTokenRepository,
       _jwtRepository = jwtRepository,
       _crypto = cryptoRepository,
       _iterations = pbkdf2Iterations,
       _accessMinutes = accessTokenMinutes,
       _refreshDays = refreshTokenDays;

  final IAuthRepository _repository;
  final IRefreshTokenRepository _refreshRepository;
  final IJwtRepository _jwtRepository;
  final IIsolateCryptoRepository _crypto;
  final int _iterations;
  final int _accessMinutes;
  final int _refreshDays;

  // ───────────── REGISTER ─────────────

  Future<Result<AuthUserDto>> register(RegisterPayload payload) async {
    final email = payload.email.trim().toLowerCase();
    final name = payload.name.trim();

    if (!email.isValidEmail) {
      return Result.failure(
        ValidationFailure(ProjectConstants.failures.invalidEmailFormat),
      );
    }
    if (!payload.password.isValidPassword) {
      return Result.failure(
        ValidationFailure(ProjectConstants.failures.invalidPasswordFormat),
      );
    }
    if (name.isEmpty || name.length > 100) {
      return const Result.failure(ValidationFailure('Ad geçersiz.'));
    }

    // E-posta zaten var mı? (asıl garanti DB'deki unique index)
    final existing = await _repository.findUserByEmail(email);
    if (existing is FailureResult<AuthUserDto?>) {
      return Result.failure(existing.failure);
    }
    if ((existing as Success<AuthUserDto?>).data != null) {
      return Result.failure(
        ValidationFailure(ProjectConstants.failures.emailAlreadyExists),
      );
    }

    // Hash'i ayrı isolate'ta üret (event loop bloklanmaz)
    final hashed = await _crypto.hashPasswordAsync(
      payload.password,
      iterations: _iterations,
    );
    if (hashed is FailureResult<String>) {
      return Result.failure(hashed.failure);
    }
    final passwordHash = (hashed as Success<String>).data;

    return _repository.createUser(
      AuthUserDto(
        id: '',
        email: email,
        name: name,
        passwordHash: passwordHash,
        role: ProjectConstants.roleUser, // ADMIN sadece DB'den verilir
      ),
    );
  }

  // ───────────── LOGIN ─────────────

  Future<Result<LoginResponse>> login(LoginPayload payload) async {
    final email = payload.email.trim().toLowerCase();

    Result<LoginResponse> wrongCredentials() => Result.failure(
      UnauthorizedFailure(
        ProjectConstants.failures.userNotFoundOrWrongPassword,
      ),
    );

    if (!email.isValidEmail) {
      return Result.failure(
        ValidationFailure(ProjectConstants.failures.invalidEmailFormat),
      );
    }
    if (payload.password.isEmpty) {
      return Result.failure(
        ValidationFailure(ProjectConstants.failures.emptyPassword),
      );
    }
    if (payload.password.length > 128) return wrongCredentials();

    final userResult = await _repository.findUserByEmail(email);
    if (userResult is FailureResult<AuthUserDto?>) {
      return Result.failure(userResult.failure);
    }
    final user = (userResult as Success<AuthUserDto?>).data;
    if (user == null) return wrongCredentials();

    final verify = await _crypto.verifyPasswordAsync(
      payload.password,
      user.passwordHash,
    );
    if (verify is FailureResult<bool>) {
      // Bozuk hash kaydı sunucu sorunudur, istemciye detay verme
      return Result.failure(ServerFailure(verify.failure.message));
    }
    if (!(verify as Success<bool>).data) return wrongCredentials();

    // Kullanıcının süresi dolmuş eski refresh token kayıtlarını temizle
    await _refreshRepository.deleteExpired(user.id);

    // Yeni oturum = yeni token ailesi
    return _issueTokens(user);
  }

  // ───────────── REFRESH ─────────────

  /// Refresh token rotasyonu: eski token iptal edilir, yenisi verilir.
  /// İptal edilmiş bir token tekrar kullanılırsa (çalıntı şüphesi)
  /// o oturumun tüm token'ları iptal edilir.
  Future<Result<LoginResponse>> refresh(RefreshPayload payload) async {
    Result<LoginResponse> invalid() => Result.failure(
      JwtFailure(ProjectConstants.failures.invalidOrExpiredToken),
    );

    final raw = payload.refreshToken.trim();
    if (raw.isEmpty || raw.length > 256) return invalid();
    final hash = _hashToken(raw);

    final found = await _refreshRepository.findByHash(hash);
    if (found is FailureResult<RefreshTokenRecord?>) {
      return Result.failure(found.failure);
    }
    final record = (found as Success<RefreshTokenRecord?>).data;
    if (record == null) return invalid();

    // Daha önce kullanılmış/iptal edilmiş token tekrar geldi: çalıntı olabilir
    if (record.revoked) {
      await _refreshRepository.revokeFamily(record.familyId);
      return invalid();
    }

    if (record.expiresAt.isBefore(DateTime.now().toUtc())) return invalid();

    // Atomik sahiplenme: aynı anda gelen ikinci istek burada elenir
    final claimed = await _refreshRepository.revoke(hash);
    if (claimed is FailureResult<bool>) {
      return Result.failure(claimed.failure);
    }
    if (!(claimed as Success<bool>).data) {
      await _refreshRepository.revokeFamily(record.familyId);
      return invalid();
    }

    // Rol vb. değişmiş olabilir, kullanıcıyı güncel haliyle yükle
    final userResult = await _repository.findUserById(record.userId);
    if (userResult is FailureResult<AuthUserDto?>) {
      return Result.failure(userResult.failure);
    }
    final user = (userResult as Success<AuthUserDto?>).data;
    if (user == null) {
      await _refreshRepository.revokeFamily(record.familyId);
      return invalid();
    }

    return _issueTokens(user, familyId: record.familyId);
  }

  // ───────────── LOGOUT ─────────────

  /// Bu cihazın oturumunu kapatır (token ailesinin tamamı iptal edilir).
  /// Token geçersiz olsa bile aynı cevabı döner, bilgi sızdırmaz.
  Future<Result<Map<String, String>>> logout(RefreshPayload payload) async {
    final raw = payload.refreshToken.trim();
    if (raw.isNotEmpty && raw.length <= 256) {
      final found = await _refreshRepository.findByHash(_hashToken(raw));
      if (found is Success<RefreshTokenRecord?>) {
        final record = found.data;
        if (record != null) {
          await _refreshRepository.revokeFamily(record.familyId);
        }
      }
    }
    return const Result.success({'message': 'Çıkış yapıldı'});
  }

  // ───────────── Yardımcılar ─────────────

  Future<Result<LoginResponse>> _issueTokens(
    AuthUserDto user, {
    String? familyId,
  }) async {
    final access = _jwtRepository.generateToken(
      JwtPayload(id: user.id, role: user.role),
    );
    if (access is FailureResult<String>) {
      return Result.failure(access.failure);
    }
    final accessToken = (access as Success<String>).data;

    final rawRefresh = _randomToken(48);
    final now = DateTime.now().toUtc();
    final saved = await _refreshRepository.save(
      RefreshTokenRecord(
        userId: user.id,
        tokenHash: _hashToken(rawRefresh),
        familyId: familyId ?? _randomToken(16),
        expiresAt: now.add(Duration(days: _refreshDays)),
        createdAt: now,
      ),
    );
    if (saved is FailureResult<bool>) {
      return Result.failure(saved.failure);
    }

    return Result.success(
      LoginResponse(
        accessToken: accessToken,
        refreshToken: rawRefresh,
        expiresIn: _accessMinutes * 60,
      ),
    );
  }

  /// Yüksek entropili rastgele token olduğu için hızlı SHA-256 yeterlidir
  /// (şifrelerdeki gibi PBKDF2 gerekmez).
  String _hashToken(String raw) => sha256.convert(utf8.encode(raw)).toString();

  String _randomToken(int byteLength) {
    final random = Random.secure();
    final bytes = List<int>.generate(byteLength, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}

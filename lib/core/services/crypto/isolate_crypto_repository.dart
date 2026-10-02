import 'package:base_backend/core/constants/project_constants.dart';
import 'package:base_backend/core/result/result.dart';
import 'package:base_backend/core/services/crypto/crypto_repository.dart';
import 'package:base_backend/core/services/crypto/crypto_requests.dart';
import 'package:base_backend/core/utils/isolate_runner.dart';

// Top-Level Isolate Fonksiyonları
Result<String> _hashPasswordInIsolate(PasswordHashRequest req) {
  final crypto = CryptoRepository();
  return crypto.hashPassword(
    req.password,
    iterations: req.iterations,
    saltLength: req.saltLength,
    keyLength: req.keyLength,
  );
}

Result<bool> _verifyPasswordInIsolate(PasswordVerifyRequest req) {
  final crypto = CryptoRepository();
  return crypto.verifyPassword(req.password, req.storedHash);
}

abstract interface class IIsolateCryptoRepository {
  Future<Result<String>> hashPasswordAsync(
    String password, {
    int? iterations,
    int saltLength = ProjectConstants.defaultSaltLength,
    int keyLength = ProjectConstants.defaultKeyLength,
  });

  Future<Result<bool>> verifyPasswordAsync(String password, String storedHash);
}

class IsolateCryptoRepository implements IIsolateCryptoRepository {
  const IsolateCryptoRepository();

  @override
  Future<Result<String>> hashPasswordAsync(
    String password, {
    int? iterations,
    int saltLength = ProjectConstants.defaultSaltLength,
    int keyLength = ProjectConstants.defaultKeyLength,
  }) async {
    final activeIterations =
        iterations ?? ProjectConstants.defaultPbkdf2Iterations;

    final request = PasswordHashRequest(
      password: password,
      iterations: activeIterations,
      saltLength: saltLength,
      keyLength: keyLength,
    );

    return IsolateRunner.run(_hashPasswordInIsolate, request);
  }

  @override
  Future<Result<bool>> verifyPasswordAsync(
    String password,
    String storedHash,
  ) async {
    final request = PasswordVerifyRequest(
      password: password,
      storedHash: storedHash,
    );

    return IsolateRunner.run(_verifyPasswordInIsolate, request);
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:base_backend/core/result/result.dart';
import 'package:crypto/crypto.dart';

/// crypto paketinin desteklediği hash algoritmaları.
enum HashAlgorithm {
  md5,
  sha1,
  sha224,
  sha256,
  sha384,
  sha512,
  sha512_224,
  sha512_256,
}

/// Çıktının hangi formatta döneceği.
enum DigestEncoding { hex, base64 }

abstract interface class ICryptoRepository {
  /// String girdiyi hash'ler.
  Result<String> hash(
    String input, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  });

  /// Ham byte listesini hash'ler.
  Result<String> hashBytes(
    List<int> bytes, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  });

  /// Stream'i parça parça hash'ler (büyük veriler için bellek dostu).
  Future<Result<String>> hashStream(
    Stream<List<int>> stream, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  });

  /// Dosya hash'i (dosya bütünlüğü / checksum kontrolü).
  Future<Result<String>> hashFile(
    File file, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  });

  /// Girdinin beklenen hash ile eşleşip eşleşmediğini sabit-zamanlı kontrol eder.
  Result<bool> verifyHash(
    String input,
    String expectedHash, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  });

  /// HMAC üretir.
  Result<String> hmac(
    String message,
    String key, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  });

  /// HMAC doğrular (sabit-zamanlı karşılaştırma).
  Result<bool> verifyHmac(
    String message,
    String key,
    String expectedHmac, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  });

  /// Kriptografik olarak güvenli rastgele salt üretir.
  Result<String> generateSalt({
    int length = 16,
    DigestEncoding encoding = DigestEncoding.base64,
  });

  /// Güvenli rastgele token üretir (API key, reset token, refresh token vb.).
  Result<String> generateSecureToken({int length = 32});

  /// PBKDF2-HMAC-SHA256 ile parola hash'ler.
  /// Çıktı formatı: pbkdf2_sha256$iterations$saltBase64$hashBase64
  Result<String> hashPassword(
    String password, {
    int iterations = 100000,
    int saltLength = 16,
    int keyLength = 32,
  });

  /// [hashPassword] ile üretilmiş kayıtlı hash'e karşı parolayı doğrular.
  Result<bool> verifyPassword(String password, String storedHash);
}

class CryptoRepository implements ICryptoRepository {
  CryptoRepository({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  static const String _passwordPrefix = 'pbkdf2_sha256';

  // ---------------------------------------------------------------------------
  // Hash
  // ---------------------------------------------------------------------------

  @override
  Result<String> hash(
    String input, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  }) {
    return hashBytes(
      utf8.encode(input),
      algorithm: algorithm,
      encoding: encoding,
    );
  }

  @override
  Result<String> hashBytes(
    List<int> bytes, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  }) {
    try {
      final digest = _resolve(algorithm).convert(bytes);
      return Result.success(_encode(digest, encoding));
    } catch (e) {
      return Result.failure(ServerFailure('Hash işlemi başarısız: $e'));
    }
  }

  @override
  Future<Result<String>> hashStream(
    Stream<List<int>> stream, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  }) async {
    try {
      final digest = await _resolve(algorithm).bind(stream).first;
      return Result.success(_encode(digest, encoding));
    } catch (e) {
      return Result.failure(ServerFailure('Stream hash işlemi başarısız: $e'));
    }
  }

  @override
  Future<Result<String>> hashFile(
    File file, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  }) async {
    try {
      if (!await file.exists()) {
        return Result.failure(
          NotFoundFailure('Dosya bulunamadı: ${file.path}'),
        );
      }
      return hashStream(
        file.openRead(),
        algorithm: algorithm,
        encoding: encoding,
      );
    } on FileSystemException catch (e) {
      return Result.failure(ServerFailure('Dosya okunamadı: ${e.message}'));
    } catch (e) {
      return Result.failure(ServerFailure('Dosya hash işlemi başarısız: $e'));
    }
  }

  @override
  Result<bool> verifyHash(
    String input,
    String expectedHash, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  }) {
    if (expectedHash.isEmpty) {
      return const Result.failure(
        ValidationFailure('Beklenen hash boş olamaz'),
      );
    }
    return hash(input, algorithm: algorithm, encoding: encoding).fold(
      onFailure: Result<bool>.failure,
      onSuccess: (computed) {
        final expected = encoding == DigestEncoding.hex
            ? expectedHash.toLowerCase()
            : expectedHash;
        return Result.success(
          _constantTimeEquals(computed.codeUnits, expected.codeUnits),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HMAC
  // ---------------------------------------------------------------------------

  @override
  Result<String> hmac(
    String message,
    String key, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  }) {
    if (key.isEmpty) {
      return const Result.failure(
        ValidationFailure('HMAC anahtarı boş olamaz'),
      );
    }
    try {
      final digest = Hmac(
        _resolve(algorithm),
        utf8.encode(key),
      ).convert(utf8.encode(message));
      return Result.success(_encode(digest, encoding));
    } catch (e) {
      return Result.failure(ServerFailure('HMAC işlemi başarısız: $e'));
    }
  }

  @override
  Result<bool> verifyHmac(
    String message,
    String key,
    String expectedHmac, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  }) {
    if (expectedHmac.isEmpty) {
      return const Result.failure(
        ValidationFailure('Beklenen HMAC boş olamaz'),
      );
    }
    return hmac(message, key, algorithm: algorithm, encoding: encoding).fold(
      onFailure: Result<bool>.failure,
      onSuccess: (computed) {
        final expected = encoding == DigestEncoding.hex
            ? expectedHmac.toLowerCase()
            : expectedHmac;
        return Result.success(
          _constantTimeEquals(computed.codeUnits, expected.codeUnits),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Random
  // ---------------------------------------------------------------------------

  @override
  Result<String> generateSalt({
    int length = 16,
    DigestEncoding encoding = DigestEncoding.base64,
  }) {
    if (length <= 0) {
      return const Result.failure(
        ValidationFailure('Salt uzunluğu 0\'dan büyük olmalı'),
      );
    }
    try {
      final bytes = _randomBytes(length);
      return Result.success(
        encoding == DigestEncoding.hex ? _toHex(bytes) : base64Encode(bytes),
      );
    } catch (e) {
      return Result.failure(ServerFailure('Salt üretilemedi: $e'));
    }
  }

  @override
  Result<String> generateSecureToken({int length = 32}) {
    if (length <= 0) {
      return const Result.failure(
        ValidationFailure('Token uzunluğu 0\'dan büyük olmalı'),
      );
    }
    try {
      return Result.success(_toHex(_randomBytes(length)));
    } catch (e) {
      return Result.failure(ServerFailure('Token üretilemedi: $e'));
    }
  }

  // ---------------------------------------------------------------------------
  // Password (PBKDF2-HMAC-SHA256)
  // ---------------------------------------------------------------------------

  @override
  Result<String> hashPassword(
    String password, {
    int iterations = 100000,
    int saltLength = 16,
    int keyLength = 32,
  }) {
    if (password.isEmpty) {
      return const Result.failure(ValidationFailure('Parola boş olamaz'));
    }
    if (iterations <= 0 || saltLength <= 0 || keyLength <= 0) {
      return const Result.failure(
        ValidationFailure(
          'iterations, saltLength ve keyLength 0\'dan büyük olmalı',
        ),
      );
    }
    try {
      final salt = _randomBytes(saltLength);
      final derived = _pbkdf2(
        utf8.encode(password),
        salt,
        iterations,
        keyLength,
      );
      return Result.success(
        '$_passwordPrefix\$$iterations\$${base64Encode(salt)}\$${base64Encode(derived)}',
      );
    } catch (e) {
      return Result.failure(ServerFailure('Parola hash işlemi başarısız: $e'));
    }
  }

  @override
  Result<bool> verifyPassword(String password, String storedHash) {
    if (password.isEmpty) {
      return const Result.failure(ValidationFailure('Parola boş olamaz'));
    }

    final parts = storedHash.split(r'$');
    if (parts.length != 4 || parts[0] != _passwordPrefix) {
      return const Result.failure(
        ValidationFailure('Kayıtlı hash formatı geçersiz'),
      );
    }

    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) {
      return const Result.failure(
        ValidationFailure('Kayıtlı hash iterasyon değeri geçersiz'),
      );
    }

    try {
      final salt = base64Decode(parts[2]);
      final expected = base64Decode(parts[3]);
      final derived = _pbkdf2(
        utf8.encode(password),
        salt,
        iterations,
        expected.length,
      );
      return Result.success(_constantTimeEquals(derived, expected));
    } on FormatException {
      return const Result.failure(
        ValidationFailure('Kayıtlı hash base64 formatı geçersiz'),
      );
    } catch (e) {
      return Result.failure(ServerFailure('Parola doğrulama başarısız: $e'));
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Hash _resolve(HashAlgorithm algorithm) => switch (algorithm) {
    HashAlgorithm.md5 => md5,
    HashAlgorithm.sha1 => sha1,
    HashAlgorithm.sha224 => sha224,
    HashAlgorithm.sha256 => sha256,
    HashAlgorithm.sha384 => sha384,
    HashAlgorithm.sha512 => sha512,
    HashAlgorithm.sha512_224 => sha512224,
    HashAlgorithm.sha512_256 => sha512256,
  };

  String _encode(Digest digest, DigestEncoding encoding) => switch (encoding) {
    DigestEncoding.hex => digest.toString(),
    DigestEncoding.base64 => base64Encode(digest.bytes),
  };

  String _toHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  Uint8List _randomBytes(int length) => Uint8List.fromList(
    List<int>.generate(length, (_) => _random.nextInt(256)),
  );

  /// Timing attack'lara karşı sabit-zamanlı karşılaştırma.
  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// RFC 8018 PBKDF2 (HMAC-SHA256).
  Uint8List _pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    final hmacSha256 = Hmac(sha256, password);
    const hashLength = 32;
    final blockCount = (keyLength / hashLength).ceil();
    final output = BytesBuilder(copy: false);

    for (var block = 1; block <= blockCount; block++) {
      final blockIndex = Uint8List(4)
        ..buffer.asByteData().setUint32(0, block, Endian.big);

      var u = hmacSha256.convert([...salt, ...blockIndex]).bytes;
      final t = Uint8List.fromList(u);

      for (var i = 1; i < iterations; i++) {
        u = hmacSha256.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      output.add(t);
    }

    return Uint8List.fromList(output.toBytes().sublist(0, keyLength));
  }
}

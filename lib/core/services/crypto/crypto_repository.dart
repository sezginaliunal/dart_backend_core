import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:base_backend/core/constants/project_constants.dart';
import 'package:base_backend/core/result/result.dart';
import 'package:crypto/crypto.dart';

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

enum DigestEncoding { hex, base64 }

abstract interface class ICryptoRepository {
  Result<String> hash(
    String input, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  });

  Result<String> hashBytes(
    List<int> bytes, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  });

  Future<Result<String>> hashStream(
    Stream<List<int>> stream, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  });

  Future<Result<String>> hashFile(
    File file, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  });

  Result<bool> verifyHash(
    String input,
    String expectedHash, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  });

  Result<String> hmac(
    String message,
    String key, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  });

  Result<bool> verifyHmac(
    String message,
    String key,
    String expectedHmac, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  });

  Result<String> generateSalt({
    int length = ProjectConstants.defaultSaltLength,
    DigestEncoding encoding = DigestEncoding.base64,
  });

  Result<String> generateSecureToken({
    int length = ProjectConstants.defaultSecureTokenLength,
  });

  Result<String> hashPassword(
    String password, {
    int? iterations,
    int saltLength = ProjectConstants.defaultSaltLength,
    int keyLength = ProjectConstants.defaultKeyLength,
  });

  Result<bool> verifyPassword(String password, String storedHash);
  Result<String> encrypt(String plainText, String secretKey);

  /// Şifrelenmiş metni gizli anahtar ile geri çözer.
  Result<String> decrypt(String cipherText, String secretKey);
}

class CryptoRepository implements ICryptoRepository {
  CryptoRepository({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

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
      return Result.failure(
        ServerFailure('${ProjectConstants.failures.unhandledException}: $e'),
      );
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
      return Result.failure(
        ServerFailure('${ProjectConstants.failures.unhandledException}: $e'),
      );
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
          NotFoundFailure(ProjectConstants.failures.fileNotFound),
        );
      }
      return await hashStream(
        file.openRead(),
        algorithm: algorithm,
        encoding: encoding,
      );
    } on FileSystemException catch (e) {
      return Result.failure(
        ServerFailure(
          '${ProjectConstants.failures.fileNotFound}: ${e.message}',
        ),
      );
    } catch (e) {
      return Result.failure(
        ServerFailure('${ProjectConstants.failures.unhandledException}: $e'),
      );
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
      return Result.failure(
        ValidationFailure(ProjectConstants.failures.emptyHashInput),
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

  @override
  Result<String> hmac(
    String message,
    String key, {
    HashAlgorithm algorithm = HashAlgorithm.sha256,
    DigestEncoding encoding = DigestEncoding.hex,
  }) {
    if (key.isEmpty) {
      return Result.failure(
        ValidationFailure(ProjectConstants.failures.emptyHmacKey),
      );
    }
    try {
      final digest = Hmac(
        _resolve(algorithm),
        utf8.encode(key),
      ).convert(utf8.encode(message));
      return Result.success(_encode(digest, encoding));
    } catch (e) {
      return Result.failure(
        ServerFailure('${ProjectConstants.failures.unhandledException}: $e'),
      );
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
      return Result.failure(
        ValidationFailure(ProjectConstants.failures.emptyHashInput),
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

  @override
  Result<String> generateSalt({
    int length = ProjectConstants.defaultSaltLength,
    DigestEncoding encoding = DigestEncoding.base64,
  }) {
    if (length <= 0) {
      return Result.failure(
        ValidationFailure(ProjectConstants.failures.invalidSaltLength),
      );
    }
    try {
      final bytes = _randomBytes(length);
      return Result.success(
        encoding == DigestEncoding.hex ? _toHex(bytes) : base64Encode(bytes),
      );
    } catch (e) {
      return Result.failure(
        ServerFailure('${ProjectConstants.failures.unhandledException}: $e'),
      );
    }
  }

  @override
  Result<String> generateSecureToken({
    int length = ProjectConstants.defaultSecureTokenLength,
  }) {
    if (length <= 0) {
      return Result.failure(
        ValidationFailure(ProjectConstants.failures.invalidTokenLength),
      );
    }
    try {
      return Result.success(_toHex(_randomBytes(length)));
    } catch (e) {
      return Result.failure(
        ServerFailure('${ProjectConstants.failures.unhandledException}: $e'),
      );
    }
  }

  @override
  Result<String> hashPassword(
    String password, {
    int? iterations,
    int saltLength = ProjectConstants.defaultSaltLength,
    int keyLength = ProjectConstants.defaultKeyLength,
  }) {
    final activeIterations =
        iterations ?? ProjectConstants.defaultPbkdf2Iterations;

    if (password.isEmpty) {
      return Result.failure(
        ValidationFailure(ProjectConstants.failures.emptyPassword),
      );
    }
    if (activeIterations <= 0 || saltLength <= 0 || keyLength <= 0) {
      return Result.failure(
        ValidationFailure(ProjectConstants.failures.invalidSaltLength),
      );
    }
    try {
      final salt = _randomBytes(saltLength);
      final derived = _pbkdf2(
        utf8.encode(password),
        salt,
        activeIterations,
        keyLength,
      );
      return Result.success(
        '${ProjectConstants.passwordPrefix}\$$activeIterations\$${base64Encode(salt)}\$${base64Encode(derived)}',
      );
    } catch (e) {
      return Result.failure(
        ServerFailure('${ProjectConstants.failures.unhandledException}: $e'),
      );
    }
  }

  @override
  Result<bool> verifyPassword(String password, String storedHash) {
    if (password.isEmpty) {
      return Result.failure(
        ValidationFailure(ProjectConstants.failures.emptyPassword),
      );
    }

    final parts = storedHash.split(r'$');
    if (parts.length != 4 || parts[0] != ProjectConstants.passwordPrefix) {
      return Result.failure(
        ValidationFailure(ProjectConstants.failures.invalidHashFormat),
      );
    }

    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) {
      return Result.failure(
        ValidationFailure(ProjectConstants.failures.invalidHashFormat),
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
      return Result.failure(
        ValidationFailure(ProjectConstants.failures.invalidHashFormat),
      );
    } catch (e) {
      return Result.failure(
        ServerFailure('${ProjectConstants.failures.unhandledException}: $e'),
      );
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

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  Uint8List _pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    final hmacSha256 = Hmac(sha256, password);
    final hashLength = ProjectConstants.pbkdf2HashLength;
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

  @override
  Result<String> encrypt(String plainText, String secretKey) {
    try {
      final key = enc.Key.fromUtf8(
        secretKey.padRight(32, '*').substring(0, 32),
      ); // 32 byte key
      final iv = enc.IV.fromSecureRandom(16); // 16 byte rastgele IV
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final encrypted = encrypter.encrypt(plainText, iv: iv);
      // IV ve ciphertext'i birlikte birleştirip base64 formatında döndürüyoruz
      final combined = '${iv.base64}:${encrypted.base64}';
      return Result.success(base64Url.encode(utf8.encode(combined)));
    } catch (e) {
      return Result.failure(ServerFailure('Şifreleme hatası: $e'));
    }
  }

  @override
  Result<String> decrypt(String cipherText, String secretKey) {
    try {
      final decodedCombined = utf8.decode(base64Url.decode(cipherText));
      final parts = decodedCombined.split(':');
      if (parts.length != 2) {
        return Result.failure(
          ValidationFailure('Geçersiz şifrelenmiş token formatı'),
        );
      }

      final iv = enc.IV.fromBase64(parts[0]);
      final encryptedData = enc.Encrypted.fromBase64(parts[1]);
      final key = enc.Key.fromUtf8(
        secretKey.padRight(32, '*').substring(0, 32),
      );
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final decrypted = encrypter.decrypt(encryptedData, iv: iv);
      return Result.success(decrypted);
    } catch (e) {
      return Result.failure(ServerFailure('Şifre çözme hatası: $e'));
    }
  }
}

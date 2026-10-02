/// Isolate'e aktarılacak hash parametreleri
final class PasswordHashRequest {
  final String password;
  final int iterations;
  final int saltLength;
  final int keyLength;

  const PasswordHashRequest({
    required this.password,
    required this.iterations,
    required this.saltLength,
    required this.keyLength,
  });
}

/// Isolate'e aktarılacak doğrulama parametreleri
final class PasswordVerifyRequest {
  final String password;
  final String storedHash;

  const PasswordVerifyRequest({
    required this.password,
    required this.storedHash,
  });
}

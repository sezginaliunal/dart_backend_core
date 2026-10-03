/// DB'de saklanan refresh token kaydı. Ham token ASLA saklanmaz, sadece SHA-256 özeti.
class RefreshTokenRecord {
  final String userId;
  final String tokenHash;

  /// Aynı oturumun (cihazın) rotasyon zinciri. Çalıntı token tespitinde
  /// zincirin tamamı iptal edilir.
  final String familyId;
  final DateTime expiresAt;
  final DateTime createdAt;
  final bool revoked;

  RefreshTokenRecord({
    required this.userId,
    required this.tokenHash,
    required this.familyId,
    required this.expiresAt,
    required this.createdAt,
    this.revoked = false,
  });

  factory RefreshTokenRecord.fromMap(Map<String, dynamic> map) =>
      RefreshTokenRecord(
        userId: map['userId'] as String,
        tokenHash: map['tokenHash'] as String,
        familyId: map['familyId'] as String,
        expiresAt: (map['expiresAt'] as DateTime).toUtc(),
        createdAt: (map['createdAt'] as DateTime).toUtc(),
        revoked: (map['revoked'] as bool?) ?? false,
      );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'tokenHash': tokenHash,
    'familyId': familyId,
    'expiresAt': expiresAt.toUtc(),
    'createdAt': createdAt.toUtc(),
    'revoked': revoked,
  };
}

/// Sadece gizli alanı olan / özel çıktı isteyen modeller implemente eder.
/// Diğer modeller için gerek yok; genel temizleme (_sanitize) yeterli.
abstract interface class ApiSerializable {
  Map<String, dynamic> toApiJson();
}

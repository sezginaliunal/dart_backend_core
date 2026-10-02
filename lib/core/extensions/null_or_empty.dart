extension ObjectX on Object? {
  /// Objenin null, boş String, boş Iterable veya boş Map olup olmadığını kontrol eder.
  bool get isNullOrEmpty {
    if (this == null) return true;
    if (this is String) return (this as String).trim().isEmpty;
    if (this is Iterable) return (this as Iterable).isEmpty;
    if (this is Map) return (this as Map).isEmpty;
    return false;
  }

  /// Objenin null veya boş olmadığını kontrol eder.
  bool get isNotNullOrEmpty => !isNullOrEmpty;
}

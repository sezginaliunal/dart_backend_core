import 'dart:async';
import 'dart:isolate';

/// Ağır CPU-bound (PBKDF2, JSON Parsing vb.) işlemleri
/// ana Event Loop'u bloklamadan çalıştırmak için generic helper.
abstract class IsolateRunner {
  const IsolateRunner._();

  /// Verilen [computation] fonksiyonunu ayrı bir Isolate içinde çalıştırır.
  static Future<R> run<T, R>(
    R Function(T message) computation,
    T message,
  ) async {
    return Isolate.run<R>(() => computation(message));
  }
}

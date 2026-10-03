import 'dart:io';
import 'package:base_backend/core/result/result.dart';
import 'package:base_backend/core/result/result_shelf_extension.dart';
import 'package:shelf/shelf.dart';

Middleware rateLimitMiddleware({
  int maxRequests = 60,
  Duration windowSize = const Duration(minutes: 1),
  bool trustProxy = false,
}) {
  final tracker = <String, List<DateTime>>{};
  var lastCleanup = DateTime.now();

  String clientKey(Request request) {
    // Sadece güvendiğin proxy arkasındaysan. Proxy'nin eklediği SON değer okunur,
    // ilk değer istemci tarafından taklit edilebilir.
    if (trustProxy) {
      final fwd = request.headers['x-forwarded-for'];
      if (fwd != null && fwd.isNotEmpty) return fwd.split(',').last.trim();
    }
    final info = request.context['shelf.io.connection_info'];
    if (info is HttpConnectionInfo) return info.remoteAddress.address;
    return 'unknown';
  }

  return (Handler inner) {
    return (Request request) async {
      final now = DateTime.now();
      final windowStart = now.subtract(windowSize);

      // Bellek sızıntısını önlemek için periyodik temizlik
      if (now.difference(lastCleanup) > windowSize) {
        tracker.removeWhere(
          (_, ts) => ts.isEmpty || ts.last.isBefore(windowStart),
        );
        lastCleanup = now;
      }

      final timestamps = tracker.putIfAbsent(clientKey(request), () => []);
      timestamps.removeWhere((t) => t.isBefore(windowStart));

      if (timestamps.length >= maxRequests) {
        return Result<Never>.failure(
          const TooManyRequestsFailure(),
        ).toResponse();
      }

      timestamps.add(now);
      return inner(request);
    };
  };
}

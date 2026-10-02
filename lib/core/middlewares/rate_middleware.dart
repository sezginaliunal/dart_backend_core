import 'package:shelf/shelf.dart';
import 'package:base_backend/core/result/result.dart';
import 'package:base_backend/core/result/result_shelf_extension.dart';

Middleware rateLimitMiddleware({
  int maxRequests = 60,
  Duration windowSize = const Duration(minutes: 1),
}) {
  final Map<String, List<DateTime>> requestTracker = {};

  return (Handler innerHandler) {
    return (Request request) async {
      final clientIp =
          request.headers['x-forwarded-for']?.split(',').first.trim() ??
          request.context['shelf.io.connection_info']?.toString() ??
          'unknown_ip';

      final now = DateTime.now();
      final windowStart = now.subtract(windowSize);

      final timestamps = requestTracker[clientIp] ?? [];
      timestamps.removeWhere((timestamp) => timestamp.isBefore(windowStart));

      if (timestamps.length >= maxRequests) {
        return Result<Never>.failure(
          const TooManyRequestsFailure(),
        ).toResponse();
      }

      timestamps.add(now);
      requestTracker[clientIp] = timestamps;

      return await innerHandler(request);
    };
  };
}

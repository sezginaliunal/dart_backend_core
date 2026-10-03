import 'package:shelf/shelf.dart';

Middleware corsMiddleware({required List<String> allowedOrigins}) {
  final allowAll = allowedOrigins.contains('*');

  String? resolveOrigin(Request request) {
    if (allowAll) return '*';
    final origin = request.headers['origin'];
    return (origin != null && allowedOrigins.contains(origin)) ? origin : null;
  }

  return (Handler inner) {
    return (Request request) async {
      final origin = resolveOrigin(request);
      final base = <String, String>{
        'Access-Control-Allow-Origin': ?origin,
        if (origin != null && !allowAll) 'Vary': 'Origin',
      };

      if (request.method == 'OPTIONS') {
        return Response(
          204,
          headers: {
            ...base,
            'Access-Control-Allow-Methods':
                'GET, POST, PUT, DELETE, OPTIONS, PATCH',
            'Access-Control-Allow-Headers':
                'Origin, Content-Type, Authorization, Accept',
            'Access-Control-Max-Age': '600',
          },
        );
      }

      final response = await inner(request);
      return response.change(headers: base);
    };
  };
}

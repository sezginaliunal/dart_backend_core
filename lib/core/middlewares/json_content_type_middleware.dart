import 'package:shelf/shelf.dart';

/// Başlığında `content-type` belirtilmemiş yanıtlar için varsayılan olarak `application/json` ekler.
Middleware jsonContentTypeMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final response = await innerHandler(request);
      if (response.headers.containsKey('content-type')) {
        return response;
      }
      return response.change(headers: {'content-type': 'application/json'});
    };
  };
}

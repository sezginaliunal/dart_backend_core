import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'result.dart';

extension ResultShelfX<T> on Result<T> {
  Response toResponse({
    int successStatusCode = 200,
    Object? Function(T data)? toJson,
  }) {
    return fold(
      onSuccess: (data) => _handleSuccess(data, successStatusCode, toJson),
      onFailure: (failure) => _handleFailure(failure),
    );
  }

  Response _handleSuccess(
    T data,
    int statusCode,
    Object? Function(T data)? customToJson,
  ) {
    Object? body;

    if (customToJson != null) {
      body = customToJson(data);
    } else if (data is List) {
      body = data.map((item) => _serializeItem(item)).toList();
    } else {
      body = _serializeItem(data);
    }

    return Response(
      statusCode,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );
  }

  Response _handleFailure(Failure failure) {
    final errorBody = jsonEncode({'error': failure.message});
    final headers = {'content-type': 'application/json'};

    return switch (failure) {
      NotFoundFailure() => Response.notFound(errorBody, headers: headers),
      ValidationFailure() => Response.badRequest(
        body: errorBody,
        headers: headers,
      ),
      UnauthorizedFailure() => Response(401, body: errorBody, headers: headers),
      ServerFailure() => Response.internalServerError(
        body: errorBody,
        headers: headers,
      ),
      NotGenerateJwtFailure() => Response(
        400,
        body: errorBody,
        headers: headers,
      ),
      JwtFailure() => Response(401, body: errorBody, headers: headers),
    };
  }

  Object? _serializeItem(dynamic item) {
    if (item == null) return null;
    try {
      return (item as dynamic).toJson();
    } catch (_) {
      return item;
    }
  }
}

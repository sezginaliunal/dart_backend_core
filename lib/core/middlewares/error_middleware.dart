import 'dart:io';
import 'package:base_backend/core/result/result.dart';
import 'package:base_backend/core/result/result_shelf_extension.dart';
import 'package:shelf/shelf.dart';

/// Yakalanmayan tüm hataları loglar ve istemciye genel 500 cevabı döner.
Middleware errorHandlerMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      try {
        return await inner(request);
      } on HijackException {
        rethrow;
      } catch (e, st) {
        stderr.writeln('[UNHANDLED] $e\n$st');
        return Result<Never>.failure(ServerFailure(e.toString())).toResponse();
      }
    };
  };
}

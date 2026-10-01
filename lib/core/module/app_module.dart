import 'package:shelf/shelf.dart';

abstract interface class AppModule {
  /// Örn: '/api/v1/users'
  String get path;
  Handler get handler;
}

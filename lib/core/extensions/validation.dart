import 'package:base_backend/core/extensions/null_or_empty.dart';

extension ValidationExtension on String {
  bool get isValidPassword => !isNullOrEmpty && length >= 5;
  bool get isValidEmail {
    if (isNullOrEmpty) return false;

    // Standart e-posta formatı için Regex
    final emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');

    return emailRegExp.hasMatch(this);
  }
}

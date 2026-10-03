import 'package:base_backend/core/constants/project_constants.dart';

extension ValidationExtension on String {
  bool get isValidPassword => length >= 8 && length <= 128;
  bool get isValidEmail =>
      length <= 254 && ProjectConstants.emailRegex.hasMatch(trim());
}

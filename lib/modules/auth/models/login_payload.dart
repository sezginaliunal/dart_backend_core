import 'package:json_annotation/json_annotation.dart';

part 'login_payload.g.dart';

@JsonSerializable()
class LoginPayload {
  final String id;
  final String email;
  final String password;

  LoginPayload({required this.id, required this.email, required this.password});
  factory LoginPayload.fromJson(Map<String, dynamic> json) =>
      _$LoginPayloadFromJson(json);
  Map<String, dynamic> toJson() => _$LoginPayloadToJson(this);
}

import 'package:json_annotation/json_annotation.dart';

part 'register_payload.g.dart';

@JsonSerializable()
class RegisterPayload {
  final String email;
  final String name;
  final String password;

  RegisterPayload({
    required this.email,
    required this.name,
    required this.password,
  });

  RegisterPayload copyWith({String? email, String? name, String? password}) {
    return RegisterPayload(
      email: email ?? this.email,
      name: name ?? this.name,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toJson() => _$RegisterPayloadToJson(this);
  factory RegisterPayload.fromJson(Map<String, dynamic> json) =>
      _$RegisterPayloadFromJson(json);
}

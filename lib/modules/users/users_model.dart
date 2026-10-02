import 'package:base_backend/core/services/mongo/object_id_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'users_model.g.dart';

@JsonSerializable()
class UsersModel {
  @JsonKey(name: '_id', includeIfNull: false)
  @ObjectIdConverter()
  final String? id;

  final String name;
  final String email;

  UsersModel({this.id, required this.name, required this.email});

  factory UsersModel.fromJson(Map<String, dynamic> json) =>
      _$UsersModelFromJson(json);

  Map<String, dynamic> toJson() => _$UsersModelToJson(this);
}

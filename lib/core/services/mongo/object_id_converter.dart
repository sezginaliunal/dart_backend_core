import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_dart/mongo_dart.dart';

/// Modelde String?, Mongo'da ObjectId.
class ObjectIdConverter implements JsonConverter<String?, Object?> {
  const ObjectIdConverter();

  @override
  String? fromJson(Object? json) {
    if (json == null) return null;
    return json is ObjectId ? json.oid : json.toString();
  }

  @override
  Object? toJson(String? id) => id == null ? null : ObjectId.parse(id);
}

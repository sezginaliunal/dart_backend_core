import 'package:json_annotation/json_annotation.dart';

part 'products_model.g.dart';

@JsonSerializable()
class ProductsModel {
  @JsonKey(fromJson: _idFromJson)
  final String id;

  const ProductsModel({required this.id});

  factory ProductsModel.fromJson(Map<String, dynamic> json) =>
      _$ProductsModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductsModelToJson(this);

  // id int olarak gelse bile String'e çevirir
  static String _idFromJson(Object? value) => value.toString();

  // TODO: Veritabanı bağlanınca sil
  static final List<ProductsModel> mock = List.generate(
    10,
    (index) => ProductsModel(id: index.toString()),
  );
}

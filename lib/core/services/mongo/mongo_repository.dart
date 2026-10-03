import 'package:base_backend/core/mixins/repository_guard.dart';
import 'package:mongo_dart/mongo_dart.dart';

/// Tüm feature'larda ortak kullanılacak repository sözleşmesi.
/// T: entity/model tipi
abstract interface class IRepository<T> {
  Future<T?> getById(String id);

  Future<List<T>> getAll({
    Map<String, dynamic>? filter,
    Map<String, int>? sort, // 1: artan, -1: azalan
    int? skip,
    int? limit,
  });

  Future<T?> getFirst(Map<String, dynamic> filter);

  Future<T> create(T item);

  Future<bool> update(String id, T item);

  Future<bool> delete(String id);

  Future<int> count({Map<String, dynamic>? filter});
}

/// Uygulama genelinde tek bir MongoDB bağlantısı yönetir (Singleton).
class MongoDatabase {
  MongoDatabase._internal();
  static final MongoDatabase instance = MongoDatabase._internal();

  Db? _db;

  bool get isConnected => _db?.isConnected ?? false;

  Db get db {
    final current = _db;
    if (current == null || !current.isConnected) {
      throw StateError(
        'MongoDB bağlı değil. Önce MongoDatabase.instance.connect(...) çağırın.',
      );
    }
    return current;
  }

  /// Örn: mongodb://localhost:27017/my_db
  /// Atlas için: mongodb+srv://user:pass@cluster.mongodb.net/my_db
  Future<void> connect(String uri, {String? dbName}) async {
    if (isConnected) return;
    final fullUri = dbName == null ? uri : _withDbName(uri, dbName);
    final database = await Db.create(fullUri);
    await database.open();
    _db = database;
  }

  /// URI'deki veritabanı adını verilen adla değiştirir (sorgu parametrelerini korur).
  static String _withDbName(String uri, String dbName) {
    final q = uri.indexOf('?');
    final base = q == -1 ? uri : uri.substring(0, q);
    final query = q == -1 ? '' : uri.substring(q);
    final schemeEnd = base.indexOf('://') + 3;
    final slash = base.indexOf('/', schemeEnd);
    final root = slash == -1 ? base : base.substring(0, slash);
    return '$root/$dbName$query';
  }

  DbCollection collection(String name) => db.collection(name);

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

abstract class MongoRepository<T>
    with RepositoryGuard
    implements IRepository<T> {
  MongoRepository({
    required this.collectionName,
    required this.fromMap,
    required this.toMap,
  });

  final String collectionName;
  final T Function(Map<String, dynamic> map) fromMap;
  final Map<String, dynamic> Function(T item) toMap;

  DbCollection get _collection =>
      MongoDatabase.instance.collection(collectionName);

  ObjectId _oid(String id) => ObjectId.parse(id);

  @override
  Future<T?> getById(String id) async {
    final doc = await _collection.findOne({'_id': _oid(id)});
    return doc == null ? null : fromMap(doc);
  }

  @override
  Future<T?> getFirst(Map<String, dynamic> filter) async {
    final doc = await _collection.findOne(filter);
    return doc == null ? null : fromMap(doc);
  }

  @override
  Future<List<T>> getAll({
    Map<String, dynamic>? filter,
    Map<String, int>? sort,
    int? skip,
    int? limit,
  }) async {
    final docs = await _collection
        .modernFind(
          filter: filter,
          sort: sort?.map((k, v) => MapEntry(k, v)),
          skip: skip,
          limit: limit,
        )
        .toList();
    return docs.map(fromMap).toList();
  }

  @override
  Future<T> create(T item) async {
    final doc = toMap(item)..remove('_id');
    final result = await _collection.insertOne(doc);
    if (!result.isSuccess || result.document == null) {
      throw StateError('Kayıt oluşturulamadı: ${result.writeError?.errmsg}');
    }
    return fromMap(result.document!);
  }

  @override
  Future<bool> update(String id, T item) async {
    final doc = toMap(item)..remove('_id');
    final result = await _collection.updateOne(
      {'_id': _oid(id)},
      {r'$set': doc},
    );
    return result.isSuccess && result.nMatched > 0;
  }

  @override
  Future<bool> delete(String id) async {
    final result = await _collection.deleteOne({'_id': _oid(id)});
    return result.isSuccess && result.nRemoved > 0;
  }

  @override
  Future<int> count({Map<String, dynamic>? filter}) =>
      _collection.count(filter);
}

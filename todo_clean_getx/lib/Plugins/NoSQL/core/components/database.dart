import '../utilities/logger.dart';
import 'basecomponent.dart';
import 'builders/binders/bindings.dart';
import 'collection.dart';
import 'commands/commandBlock.dart';

class Database extends BaseComponent {
  Map<String, Collection> _collections = {};
  List<Binding> _binders = [];

  Database({
    super.objectId,
    required super.name,
    super.timestamp,
    super.type = NoSQLType.DATABASE,
  });

  Future<bool> setBinding({
    required Collection parent,
    required Collection child,
    required String key,
    Type expectedType = String,
  }) async {
    CommandBlock<Binding> block = CommandBlock();

    var binder = Binding(
      database: this,
      parent: parent,
      child: child,
      expectedType: expectedType,
      key: key,
    );

    block.setCommands(doFunc: (_) async {
      _binders.add(binder);
      return await binder.init();
    }, undoFunc: (_, __) async {
      return await binder.dispose();
    });

    return await initBlock(block);
  }

  factory Database.fromJson(Map<String, dynamic> data) {
    Database db = Database(
      objectId: data["_objectId"],
      name: data["name"],
      timestamp: data["timestamp"] == null
          ? DateTime.now()
          : DateTime.tryParse(data["timestamp"]),
    );

    try {
      Map<String, dynamic>? jsonCollections = data["collections"];

      if (jsonCollections == null) return db;

      Map<String, Collection> collections = {};

      for (var entry in jsonCollections.entries) {
        var key = entry.key;
        var value = entry.value;

        Map<String, dynamic> temp_entries = {};

        value.forEach((key, value) {
          temp_entries.addAll({key: value});
        });

        if (temp_entries.isEmpty) continue;

        collections.addAll({key: Collection.fromJson(db, temp_entries)});
      }

      db.collections = collections;
    } catch (e) {
      Logging().print_and_log(
        "Error $e occured in database.fromJson, failed to initialize collections",
      );
    }

    return db;
  }

  Map<String, Collection> get collections => _collections;

  set collections(Map<String, Collection> data) => _collections = data;

  Future<bool> addCollection({Collection? collection}) async {
    CommandBlock<Collection> block = CommandBlock();

    block.setCommands(
      doFunc: (setRef) async {
        if (collection == null) return false;
        String name = collection.name!;
        if (_collections[name] != null || name.isEmpty) {
          if (_collections[name] != null) {
            print_and_log(
              "Failed to create Collection -> $name Collection exists",
            );
          }
          if (name.isEmpty) {
            print_and_log(
              "Failed to create Collection -> $name can not be empty",
            );
          }
          return false;
        }

        _collections.addAll({name: collection});
        setRef(collection);

        return true;
      },
      undoFunc: (ref, __) async {
        if (ref == null) return false;
        String name = ref.name!;
        _collections.remove(name);

        return true;
      },
    );

    return await initBlock(block);
  }

  Future<Collection?> getCollection({required String name}) async {
    return _collections[name];
  }

  Future<Collection?> getCollectionByObjectId({String? objectId}) async {
    Collection? collection;

    var col = _collections.values
        .where((collection) => collection.objectId == objectId);

    if (col.isNotEmpty) collection = col.first;

    return collection;
  }

  Future<bool> removeCollection({required Collection collection}) async {
    CommandBlock<Collection> block = CommandBlock();

    block.setCommands(
      doFunc: (setRef) async {
        String name = collection.name!;
        if (_collections[name] == null || name.isEmpty) {
          if (_collections[name] == null) {
            print_and_log(
              "Failed to remove Collection -> $name Collection does not exists",
            );
          }
          if (name.isEmpty) {
            print_and_log(
              "Failed to create Collection -> $name can not be empty",
            );
          }
          return false;
        }
        _collections.remove(collection.name);
        logger_log("$name Collection has been removed");
        setRef(collection);
        return true;
      },
      undoFunc: (ref, __) async {
        if (ref == null) return false;
        String name = collection.name!;
        if (_collections[name] != null || name.isEmpty) {
          if (_collections[name] != null) {
            print_and_log(
              "Failed to create Collection -> $name Collection exists",
            );
          }
          if (name.isEmpty) {
            print_and_log(
              "Failed to create Collection -> $name can not be empty",
            );
          }
          return false;
        }
        _collections.addAll({name: collection});
        logger_log("$name Collection has been added");
        return true;
      },
    );
    return await initBlock(block);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, Map> temp_entries = {};
    _collections.forEach((key, value) {
      temp_entries.addAll({key: value.toJson()});
    });

    return super.toJson()
      ..addAll({
        "number_of_collections": _collections.length,
        "collections": temp_entries,
      });
  }
}

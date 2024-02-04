import 'components/builders/queryBuilders/baseQueryBuilder.dart';
import 'components/builders/restrictionBuilder.dart';
import 'components/collection.dart';
import 'components/commands/commandBlock.dart';
import 'components/database.dart';
import 'components/document.dart';
import 'components/nosqlTransaction/nosqlTransactionManager.dart';
import 'nosqlManager.dart';
import 'utilities/logger.dart';

class NoSQLUtility extends Logging {
  NoSQLManager _manager = NoSQLManager();
  NoSQLTransactionManager _transactionManager = NoSQLTransactionManager();

  Future<void> initialize() => _manager.initialize();
  Future<void> commit() => _manager.commit();

  Map<String, Database> get databases => _manager.databases;
  Database? get currentDatabase => _manager.currentDatabase;

  Future<bool> _addBlockToTransaction(CommandBlock block) async {
    return await _transactionManager.addTransactionBlock(block);
  }

  Future<bool> initBlock(CommandBlock block) async {
    bool results = await _addBlockToTransaction(block);
    if (results) return true;

    if (_transactionManager.currentTransaction == null) {
      return await block.execute();
    }

    return false;
  }

  Future<bool> setCurrentDatabase({String? name}) async {
    CommandBlock<Database?> block = CommandBlock();

    block.setCommands(
      doFunc: (setRef) async {
        setRef(_manager.currentDatabase);
        name == null
            ? _manager.currentDatabase = null
            : _manager.currentDatabase = await getDatabase(name: name);

        return true;
      },
      undoFunc: (ref, _) async {
        _manager.currentDatabase = ref;
        return true;
      },
    );

    return await initBlock(block);
  }

  Future<bool> setRestrictions({
    required String reference,
    required RestrictionBuilder restrictions,
  }) async {
    CommandBlock<(Collection, RestrictionBuilder)> block = CommandBlock();

    block.setCommands(
      doFunc: (setRef) async {
        Collection? collection = await getCollection(reference: reference);
        if (collection == null) return false;

        setRef((collection, collection.restrictions));
        return collection.setRestrictions(restrictions);
      },
      undoFunc: (ref, _) async {
        if (ref == null) return false;

        return await ref.$1.setRestrictions(ref.$2);
      },
    );

    return await initBlock(block);
  }

  Future<bool> createDatabase({
    String? objectId,
    required String name,
    DateTime? timestamp,
  }) async {
    Database? db = databases[name];

    CommandBlock<Database> block = CommandBlock();

    block.setCommands(
      doFunc: (setRef) async {
        if (name.isEmpty) {
          print_and_log("Failed to create Database. name can not be empty");
          return false;
        }
        if (db != null) {
          print_and_log("Failed to create $name database, database exists");
          return false;
        }
        var database =
            Database(objectId: objectId, name: name, timestamp: timestamp);
        databases.addAll({
          name: database,
        });
        logger_log("$name database successfully created");
        setRef(database);

        return true;
      },
      undoFunc: (ref, _) async {
        if (ref == null) return true;
        databases.remove(name);
        return true;
      },
    );

    return await initBlock(block);
  }

  Future<Database?> getDatabase({required String name}) async {
    Database? db = databases[name];
    return db;
  }

  Future<bool> deleteDatabase({required String name}) async {
    Database? db = databases[name];

    CommandBlock block = CommandBlock();

    block.setCommands(
      doFunc: (_) async {
        try {
          if (db == null) {
            print_and_log(
              "Failed to delete $name database, database does not exists",
            );
            return false;
          }
          databases.remove(name);
          logger_log("$name database successfully deleted");
        } catch (e) {
          print_and_log("Failed to delete $name database, error ocurred -> $e");
          return false;
        }
        return true;
      },
      undoFunc: (_, __) async {
        if (db == null) return false;
        databases[name] = db;
        return true;
      },
    );

    return await initBlock(block);
  }

  Future<bool> createCollection({required String reference}) async {
    CommandBlock<(Database, Collection)> block = CommandBlock();

    block.setCommands(
      doFunc: (setRef) async {
        Database? database;
        String collectionName;
        if (reference.contains(".")) {
          database = await getDatabase(name: reference.split(".")[0]);
          collectionName = reference.split(".")[1];
        } else {
          database = currentDatabase;
          collectionName = reference;
        }

        if (database == null || collectionName.isEmpty) return false;
        var collection = Collection(name: collectionName, database: database);

        setRef((database, collection));
        return await database.addCollection(collection: collection);
      },
      undoFunc: (ref, _) async {
        return true;
      },
    );

    return await initBlock(block);
  }

  Future<Collection?> getCollection({required String reference}) async {
    Database? database;
    Collection? collection;

    if (reference.contains(".")) {
      database = await getDatabase(name: reference.split(".")[0]);
      collection = await database?.getCollection(name: reference.split(".")[1]);
    } else {
      database = currentDatabase;
      collection = await database?.getCollection(name: reference);
    }

    if (database == null || collection == null) return null;

    return collection;
  }

  Future<bool> deleteCollection({required String reference}) async {
    CommandBlock<Collection> block = CommandBlock();

    block.setCommands(doFunc: (setRef) async {
      Collection? collection = await getCollection(reference: reference);

      if (collection == null) return false;
      setRef(collection);
      return await collection.database.removeCollection(collection: collection);
    }, undoFunc: (ref, _) async {
      return true;
    });

    return await initBlock(block);
  }

  Future<bool> setCollectionBinding({
    required String parentCollectionRef,
    required String childCollectionRef,
    required String key,
    Type expectedType = String,
  }) async {
    CommandBlock block = CommandBlock();

    block.setCommands(doFunc: (_) async {
      Collection? parentCollection =
          await getCollection(reference: parentCollectionRef);
      Collection? childCollection =
          await getCollection(reference: childCollectionRef);

      if (parentCollection == null || childCollection == null) return false;

      var db = parentCollection.database;

      return await db.setBinding(
        parent: parentCollection,
        child: childCollection,
        key: key,
        expectedType: expectedType,
      );
    }, undoFunc: (_, __) async {
      return true;
    });

    return await initBlock(block);
  }

  Future<bool> insertDocument({
    required String reference,
    required Map<String, dynamic> data,
  }) async {
    CommandBlock<(Collection, Document)> block = CommandBlock();

    block.setCommands(
      doFunc: (setRef) async {
        Collection? collection = await getCollection(reference: reference);
        if (collection == null) return false;
        Document document = Document(collection: collection);
        document.addField(field: data);

        if (!await collection.addDocument(document: document)) return false;
        setRef((collection, document));

        return true;
      },
      undoFunc: (ref, _) async {
        return true;
      },
    );

    return await initBlock(block);
  }

  Future<bool> insertDocuments({
    required String reference,
    required List<Map<String, dynamic>> data,
  }) async {
    CommandBlock<(Collection, List<Document>)> block = CommandBlock();

    block.setCommands(
      doFunc: (setRef) async {
        Collection? collection = await getCollection(reference: reference);
        print(collection);
        if (collection == null) return false;

        List<Document> documents = data.map((field) {
          Document document = Document(collection: collection);
          document.addField(field: field);
          return document;
        }).toList();

        await collection.addDocuments(documents: documents);

        setRef((collection, documents));

        return true;
      },
      undoFunc: (ref, _) async {
        return true;
      },
    );

    return await initBlock(block);
  }

  Future<Document?> getDocument({
    required String reference,
    required BaseQueryBuilder query,
  }) async {
    Collection? collection = await getCollection(reference: reference);

    if (collection == null) return null;

    return collection.getDocument(query: query);
  }

  Future<List<Document>> getDocuments({
    required String reference,
    BaseQueryBuilder? query,
  }) async {
    Collection? collection = await getCollection(reference: reference);

    if (collection == null) return [];

    return collection.getDocuments(query: query);
  }

  Future<bool> updateDocument({
    required String reference,
    required BaseQueryBuilder query,
    required Map<String, dynamic> data,
    List<String>? ignoreKeys,
  }) async {
    CommandBlock<(Document, Map<String, dynamic>)> block = CommandBlock();

    block.setCommands(
      doFunc: (setRef) async {
        Collection? collection = await getCollection(reference: reference);
        if (collection == null) return false;

        Document? document = await collection.getDocument(query: query);

        if (document == null) return false;

        var initialData = document.fields;

        if (!await collection.updateDocument(document: document, data: data))
          return false;

        setRef((document, initialData));

        return true;
      },
      undoFunc: (ref, _) async {
        return true;
      },
    );

    return await initBlock(block);
  }

  Future<bool> updateDocuments({
    required String reference,
    BaseQueryBuilder? query,
    required Map<String, dynamic> data,
    List<String>? ignoreKeys,
  }) async {
    CommandBlock<(Collection, List<Map<String, dynamic>>)> block =
        CommandBlock();

    block.setCommands(
      doFunc: (setRef) async {
        Collection? collection = await getCollection(reference: reference);
        if (collection == null) return false;

        List<Document> documents = await collection.getDocuments(query: query);
        List<Map<String, dynamic>> initialFields =
            documents.map((e) => e.toJson()).toList();

        await collection.updateDocuments(
          documents: documents,
          data: data,
          ignoreKeys: ignoreKeys,
        );

        setRef((collection, initialFields));

        return true;
      },
      undoFunc: (ref, _) async {
        return true;
      },
    );
    return await initBlock(block);
  }

  Future<bool> removeDocument({
    required String reference,
    required BaseQueryBuilder query,
  }) async {
    CommandBlock<(Collection, Document)> block = CommandBlock();

    block.setCommands(
      doFunc: (setRef) async {
        Collection? collection = await getCollection(reference: reference);

        if (collection == null) return false;

        var document = await collection.getDocument(query: query);

        if (document == null) return false;

        if (!await collection.removeDocument(
          document: document,
        )) return false;

        setRef((collection, document));

        return true;
      },
      undoFunc: (ref, _) async {
        return true;
      },
    );

    return await initBlock(block);
  }

  Future<bool> removeDocuments({
    required String reference,
    required BaseQueryBuilder query,
  }) async {
    CommandBlock<(Collection, List<Document>)> block = CommandBlock();

    block.setCommands(
      doFunc: (setRef) async {
        Collection? collection = await getCollection(reference: reference);
        if (collection == null) return false;
        var documents = await collection.getDocuments(query: query);
        await collection.removeDocuments(
          documents: documents,
        );

        setRef((collection, documents));

        return true;
      },
      undoFunc: (ref, _) async {
        return true;
      },
    );

    return await initBlock(block);
  }
}

import 'dart:async';
import '../utilities/logger.dart';
import 'basecomponent.dart';
import 'builders/queryBuilders/baseQueryBuilder.dart';
import 'builders/restrictionBuilder.dart';
import 'commands/commandBlock.dart';
import 'database.dart';
import 'document.dart';

class Collection extends BaseComponent {
  final _streamController = StreamController<List<Document>>.broadcast();
  Stream<List<Document>> get stream => _streamController.stream;

  Database database;
  Map<String, Document> _documents = {};
  RestrictionBuilder _restrictions = RestrictionBuilder();
  CommandBlock<Document> block = CommandBlock();

  final CallbackObject<Document> addDocumentCallbackObject = CallbackObject();
  final CallbackObject<List<Document>> addDocumentsCallbackObject =
      CallbackObject();

  final CallbackObject<Document> deleteDocumentCallbackObject =
      CallbackObject();
  final CallbackObject<List<Document>> deleteDocumentsCallbackObject =
      CallbackObject();

  Collection({
    super.objectId,
    required super.name,
    super.timestamp,
    required this.database,
    super.type = NoSQLType.COLLECTION,
  });

  factory Collection.fromJson(Database db, Map<String, dynamic> data) {
    Collection collection = Collection(
      objectId: data["_objectId"],
      name: data["name"],
      database: db,
      timestamp: data["timestamp"] == null
          ? DateTime.now()
          : DateTime.tryParse(data["timestamp"]),
    );

    try {
      Map<String, dynamic>? jsonDocuments = data["documents"];

      if (jsonDocuments == null) return collection;

      Map<String, Document> documents = {};

      for (var entry in jsonDocuments.entries) {
        var key = entry.key;
        var value = entry.value;

        Map<String, dynamic> temp_entries = {};

        value.forEach((key, value) {
          temp_entries.addAll({key: value});
        });

        if (temp_entries.isEmpty) continue;

        documents.addAll({key: Document.fromJson(collection, temp_entries)});
      }

      collection.documents = documents;

      Map<String, dynamic>? jsonRestrictions = data["restrictions"];

      if (jsonRestrictions == null) return collection;

      collection.setRestrictions(
        RestrictionBuilder.fromJson(data: jsonRestrictions),
        override: true,
      );
    } catch (e) {
      Logging().print_and_log(
        "Error $e occured in Collection.fromJson, failed to initialize documents",
      );
    }

    return collection;
  }

  Map<String, Document> get documents => _documents;

  List<Map<String, dynamic>> get documentsJson =>
      _documents.values.map((x) => x.toJson()).toList();

  List<Map<String, dynamic>> get documentsField =>
      _documents.values.map((x) => x.fields).toList();

  set documents(Map<String, Document> data) => _documents = data;

  void _broadcastChanges() {
    _streamController.add(List<Document>.from(_documents.values.toList()));
  }

  void dispose() {
    _streamController.close();
  }

  void addDocumentListner(
      Future<void> Function(
              Document document, void Function(bool res) setResults)
          callback) {
    addDocumentCallbackObject.listen(callback);
  }

  void addDocumentsListner(
    Future<void> Function(
            List<Document> documents, void Function(bool res) setResults)
        callback,
  ) {
    addDocumentsCallbackObject.listen(callback);
  }

  void deleteDocumentListner(
      Future<void> Function(
              Document document, void Function(bool res) setResults)
          callback) {
    deleteDocumentCallbackObject.listen(callback);
  }

  void deleteDocumentsListner(
    Future<void> Function(
            List<Document> documents, void Function(bool res) setResults)
        callback,
  ) {
    deleteDocumentsCallbackObject.listen(callback);
  }

  RestrictionBuilder get restrictions => _restrictions;

  Future<bool> setRestrictions(
    RestrictionBuilder restriction, {
    bool override = false,
    String? id,
  }) async {
    CommandBlock<RestrictionBuilder> block = CommandBlock();

    block.setCommands(
      doFunc: (setRef) async {
        bool valid = restriction.valid;

        if (!valid && !override) return false;

        setRef(_restrictions);
        _restrictions = restriction;
        return true;
      },
      undoFunc: (ref, __) async {
        if (ref == null) return false;
        _restrictions = ref;
        return true;
      },
    );

    return await initBlock(block);
  }

  Future<bool> addDocument({String? id, required Document document}) async {
    block = CommandBlock();

    block.setCommands(
      doFunc: (_) async {
        bool results =
            await documentRestrictionsInterpreter(document: document);
        if (!results || _documents[document.objectId] != null) {
          print_and_log("Failed to add document. ${document.objectId}");
          return false;
        }

        await addDocumentCallbackObject.execute(
          ref: document,
          setResults: (res) {
            results = res;
          },
        );

        if (results) {
          _documents[document.objectId as String] = document;
          _broadcastChanges();
        }

        return results;
      },
      undoFunc: (_, __) async {
        _documents.remove(document.objectId);
        _broadcastChanges();
        return true;
      },
    );

    return await initBlock(block);
  }

  Future<bool> addDocuments({
    String? id,
    required List<Document> documents,
  }) async {
    CommandBlock<List<Document>> block = CommandBlock();

    block.setCommands(
      doFunc: (setRef) async {
        bool results = true;
        List<Document> insertedDocuments = [];
        for (var document in documents) {
          results = await documentRestrictionsInterpreter(document: document);
          if (!results || _documents[document.objectId] != null) {
            print_and_log(
              "Failed to add documents. exiting process. problematic document -> ${document.toJson()}",
            );
            break;
          }
          _documents[document.objectId as String] = document;
          insertedDocuments.add(document);
        }
        setRef(insertedDocuments);
        await addDocumentsCallbackObject.execute(
          ref: insertedDocuments,
          setResults: (res) {
            results = res;
          },
        );
        if (results) _broadcastChanges();
        return results;
      },
      undoFunc: (ref, __) async {
        var documents = ref;
        if (documents == null) return false;
        for (var document in documents) {
          _documents.remove(document.objectId);
        }
        _broadcastChanges();
        return true;
      },
    );

    return await initBlock(block);
  }

  Future<Document?> getDocument({
    String? id,
    required BaseQueryBuilder query,
  }) async {
    var documents = await _documentQueryInterpreter(query: query);

    if (documents.isEmpty) return null;

    return documents.first;
  }

  Future<List<Document>> getDocuments({BaseQueryBuilder? query}) async {
    List<Document> docs = [];

    if (query == null) return _documents.values.map((x) => x).toList();

    docs = await _documentQueryInterpreter(query: query);

    return docs;
  }

  Future<bool> removeDocument({
    String? id,
    required Document document,
  }) async {
    block = CommandBlock();

    block.setCommands(doFunc: (_) async {
      bool results = true;
      _documents.remove(document.objectId);

      if (_documents[document.objectId] != null) {
        print_and_log("Failed to remove document");
        return false;
      }
      await deleteDocumentCallbackObject.execute(
        ref: document,
        setResults: (res) {
          results = res;
        },
      );
      _broadcastChanges();
      return results;
    }, undoFunc: (_, __) async {
      _documents.addAll({document.objectId!: document});
      _broadcastChanges();
      return true;
    });

    return await initBlock(block);
  }

  Future<bool> removeDocuments({
    String? id,
    required List<Document> documents,
  }) async {
    CommandBlock<List<Document>> block = CommandBlock();

    block.setCommands(
      doFunc: (setRef) async {
        bool results = true;
        List<Document> removedDocuments = [];
        for (var document in documents) {
          _documents.remove(document.objectId);

          if (_documents[document.objectId] != null) {
            print_and_log(
              "Failed to remove documents. exiting process. problematic document -> ${document.toJson()}",
            );
            results = false;
            break;
          }
          removedDocuments.add(document);
        }
        setRef(removedDocuments);
        await deleteDocumentsCallbackObject.execute(
          ref: removedDocuments,
          setResults: (res) {
            results = res;
          },
        );

        _broadcastChanges();
        return results;
      },
      undoFunc: (ref, __) async {
        var documents = ref;
        if (documents == null) return false;
        for (var document in documents) {
          _documents.addAll({document.objectId!: document});
        }
        _broadcastChanges();
        return true;
      },
    );

    return await initBlock(block);
  }

  Future<bool> updateDocument({
    String? id,
    required Document document,
    required Map<String, dynamic> data,
    List<String>? ignoreKeys,
    bool triggerCallback = true,
  }) async {
    CommandBlock<Map<String, dynamic>> block = CommandBlock();

    block.setCommands(doFunc: (setRef) async {
      var dataList = _documents.values
          .where((x) => x.objectId != document.objectId)
          .map((e) => e.toJson())
          .toList();

      var results =
          await _restrictions.interpret(data: data, dataList: dataList);
      if (!results) {
        logger_log(
          "Failed Update document: ${document.objectId}. Data $data violates collection restrictions",
        );
        return false;
      }

      Map<String, dynamic> initialData = document.fields;
      results = document.updateFields(data, ignoreKeys: ignoreKeys);
      setRef(initialData);
      _broadcastChanges();
      return true;
    }, undoFunc: (ref, __) async {
      Map<String, dynamic>? initialData = ref;
      if (initialData == null) return false;
      var results = document.updateFields(initialData, ignoreKeys: ignoreKeys);
      _broadcastChanges();
      return results;
    });

    return await initBlock(block);
  }

  Future<bool> updateDocuments({
    String? id,
    required List<Document> documents,
    required Map<String, dynamic> data,
    List<String>? ignoreKeys,
  }) async {
    CommandBlock<List<Map<String, dynamic>>> block = CommandBlock();

    block.setCommands(doFunc: (setRef) async {
      List<Map<String, dynamic>> initialFields = [];

      var results = true;
      for (var document in documents) {
        var dataList = _documents.values
            .where((x) => x.objectId != document.objectId)
            .map((e) => e.toJson())
            .toList();

        results = await _restrictions.interpret(data: data, dataList: dataList);
        if (results) {
          initialFields.add(document.fields);
          results = document.updateFields(data);
        }
        if (!results) {
          logger_log(
            "Failed Update document: ${document.objectId}. Data $data violates collection restrictions",
          );
          break;
        }
      }
      setRef(initialFields);
      _broadcastChanges();
      return results;
    }, undoFunc: (ref, __) async {
      var initialFields = ref;
      if (initialFields == null) return false;
      for (var fields in initialFields) {
        var document = _documents[fields["_objectId"]];
        if (document == null) continue;
        document.updateFields(fields);
      }
      _broadcastChanges();
      return true;
    });

    return await block.execute();
  }

  Future<List<Document>> _documentQueryInterpreter({
    required BaseQueryBuilder query,
  }) async {
    var results = await query.interpret(
        data: _documents.values.map((x) => x.fields).toList());

    List<Document> array = [];

    for (var data in results) {
      var objectId = data["_objectId"];

      if (objectId == null) continue;

      Document? document = _documents[objectId];
      if (document != null) array.add(document);
    }

    return array;
  }

  Future<bool> documentRestrictionsInterpreter({
    required Document document,
  }) async {
    bool results = true;
    List<Map<String, dynamic>> documents =
        _documents.values.map((x) => x.fields).toList();
    try {
      results = await restrictions.interpret(
          data: document.fields, dataList: documents);
    } catch (e) {
      results = false;
    }

    return results;
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, Map> tempEntries = {};
    _documents.forEach((key, value) {
      tempEntries.addAll({key: value.toJson()});
    });
    return super.toJson()
      ..addAll({
        "database": database.objectId,
        "number_of_documents": _documents.length,
        "restrictions": _restrictions.toJson(),
        "documents": tempEntries,
      });
  }
}

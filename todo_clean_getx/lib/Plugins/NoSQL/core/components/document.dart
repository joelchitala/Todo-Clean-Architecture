import '../utilities/utils.dart';
import 'basecomponent.dart';
import 'collection.dart';

class Document extends BaseComponent {
  final Collection collection;
  Map<String, dynamic> _fields = {};

  List<String> _forbidenKeys = ["_objectId"];

  Map<String, dynamic> get fields => _fields;

  bool setFields(Map<String, dynamic>? data, {bool override = false}) {
    _fields = {};
    _fields.addAll({"_objectId": objectId});

    if (data == null) return false;

    for (var x in data.entries) {
      if (x.key == "_objectId" && !override) continue;

      _fields.addAll({x.key: x.value});
    }

    return true;
  }

  Document({
    super.objectId,
    super.timestamp,
    required this.collection,
    super.type = NoSQLType.DOCUMENT,
  }) {
    _fields.addAll({"_objectId": objectId});
  }

  factory Document.fromJson(Collection collection, Map<String, dynamic> data) {
    Document document = Document(
      objectId: data["_objectId"],
      collection: collection,
      timestamp: data["timestamp"] == null
          ? DateTime.now()
          : DateTime.tryParse(data["timestamp"]),
    );

    document.setFields(data["fields"]);

    return document;
  }

  factory Document.update(Document document, Map<String, dynamic> data) {
    Document doc = Document(
      objectId: document.objectId,
      collection: document.collection,
      timestamp: data["timestamp"] == null
          ? document.timestamp
          : DateTime.tryParse(data["timestamp"]) ?? DateTime.now(),
    );

    doc.setFields(data["fields"] ?? document.fields);

    return doc;
  }

  bool addField({
    required Map<String, dynamic> field,
    List<String>? ignoreKeys,
  }) {
    bool results = true;

    try {
      List<String> forbidenKeys = [...fields.keys];

      if (isSubset(set1: forbidenKeys, set2: field.keys.toList())) return false;
      _fields.addAll(field);
    } catch (e) {
      print(e);
    }

    return results;
  }

  bool updateFields(Map<String, dynamic> data, {List<String>? ignoreKeys}) {
    try {
      if (ignoreKeys != null) {
        for (var key in ignoreKeys) {
          data.remove(key);
        }
      }

      for (var key in data.keys) {
        if (_forbidenKeys.contains(key)) {
          logger_log("Key $key is immutable -> document $objectId field $data");
          return false;
        }
      }

      _fields.addAll(data);
      logger_log("Updated to document $objectId data to $data");

      return true;
    } catch (e) {
      print_and_log("Failed to update document $objectId. Error -> $e occured");
    }
    return false;
  }

  bool removeField(String key) {
    try {
      if (_forbidenKeys.contains(key)) {
        logger_log("Key $key can not be removed -> document $objectId");
        return false;
      }
      _fields.remove(key);
      logger_log("Successfully to remove field with (key: $key) from document");

      return true;
    } catch (e) {
      print_and_log("Failed to remove field with (key: $key) from document");
      return false;
    }
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "collection": collection.objectId,
      "number_of_fields": _fields.length,
      "fields": _fields,
    });
}

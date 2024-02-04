import '../../collection.dart';
import '../../database.dart';
import '../../document.dart';
import '../queryBuilders/queryBuilder.dart';
import '../restrictionBuilder.dart';

class Binding<T extends Collection, H extends Collection> {
  final Database database;
  T parent;
  H child;
  Type expectedType;
  String key;
  RestrictionFieldObject? initialFieldObject;
  String _objectId = "_objectId";

  Binding({
    required this.database,
    required this.parent,
    required this.child,
    required this.expectedType,
    required this.key,
  }) {
    // init();
  }

  Future<void> _childListener(
    Document document,
    void Function(bool res) setResults,
  ) async {
    var doc = await parent.getDocument(
      query: QueryBuilder().eq(
        key: _objectId,
        values: [document.fields[key]],
      ),
    );
    if (document.fields[key] == null || doc == null) setResults(false);
  }

  Future<void> _parentListener(
    document,
    void Function(bool res) setResults,
  ) async {
    child.removeDocuments(
      documents: child.documents.values
          .where((x) => x.fields[key] == document.objectId)
          .toList(),
    );
  }

  Future<bool> init() async {
    if ((parent.database != child.database) ||
        (database != parent.database || database != child.database)) {
      return false;
    }

    try {
      initialFieldObject = child.restrictions.getFieldObject(key);
      child.restrictions.removeRestrictionFieldObject(key: key);
      child.restrictions.restrictField(
        key: key,
        isRequired: true,
        unique: true,
        expectedType: expectedType,
        binder: this,
      );

      child.addDocumentListner(_childListener);
      parent.deleteDocumentListner(_parentListener);

      return true;
    } catch (e) {
      print(e);
    }

    return false;
  }

  void interpret() {}

  Future<bool> dispose() async {
    try {
      var object = child.restrictions.getFieldObject(key);
      if (object != null) {
        if (object.binder == this) {
          child.restrictions.removeRestrictionFieldObject(key: key);
          if (initialFieldObject != null) {
            child.restrictions.addRestrictionFieldObject(initialFieldObject!);
          }
        }
      }
      child.addDocumentCallbackObject.discard(_childListener);
      parent.deleteDocumentCallbackObject.discard(_parentListener);
      return true;
    } catch (e) {
      print(e);
    }

    return false;
  }
}

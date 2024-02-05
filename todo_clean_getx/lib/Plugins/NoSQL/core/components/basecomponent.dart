import '../utilities/logger.dart';
import '../utilities/utils.dart';
import 'commands/commandBlock.dart';
import 'nosqlTransaction/nosqlTransactionManager.dart';

enum NoSQLType {
  DATABASE,
  COLLECTION,
  DOCUMENT,
  TRIGGER,
  PROCEDURE,
}

NoSQLType? toNoSQLType(String type) {
  for (var value in NoSQLType.values) {
    if (value.toString() == type) return value;
  }
  return null;
}

class CallbackObject<T> {
  String key;
  List<Future<void> Function(T ref, void Function(bool res) setResults)>
      _callbacks = [];

  CallbackObject({this.key = ""});

  bool listen(
    Future<void> Function(T ref, void Function(bool res) setResults) callback,
  ) {
    try {
      _callbacks.add(callback);
      return true;
    } catch (e) {
      print(e);
    }
    return false;
  }

  bool discard(
    Future<void> Function(T ref, void Function(bool res) setResults) callback,
  ) {
    try {
      _callbacks.remove(callback);
      return true;
    } catch (e) {
      print(e);
    }
    return false;
  }

  Future<bool> execute({
    required T ref,
    required void Function(bool res) setResults,
  }) async {
    try {
      for (var callback in _callbacks) {
        await callback(ref, setResults);
      }
      return true;
    } catch (e) {
      print(e);
    }

    return false;
  }

  bool dispose() {
    try {
      _callbacks = [];
      return true;
    } catch (e) {
      print(e);
    }
    return false;
  }
}

class BaseComponent extends Logging {
  String? objectId;
  String? name;
  DateTime? timestamp;
  NoSQLType? type;

  final NoSQLTransactionManager _transactionManager = NoSQLTransactionManager();

  BaseComponent({
    this.objectId,
    this.name,
    this.timestamp,
    this.type,
  }) {
    objectId = objectId ?? "${type!.name}_${generateUUID()}";
    timestamp = timestamp ?? DateTime.now();
  }

  Future<bool> _addBlockToTransaction(CommandBlock block) async {
    return await _transactionManager.addTransactionBlock(block);
  }

  Future<bool> initBlock(CommandBlock block) async {
    bool results = await _addBlockToTransaction(block);
    if (results) return true;

    if (_transactionManager.currentTransaction == null) {
      var results = await block.execute();
      return results;
    }

    return false;
  }

  Map<String, dynamic> toJson() => {
        "_objectId": objectId,
        "type": type.toString(),
        "name": name,
        "timestamp": timestamp?.toIso8601String(),
      };
}

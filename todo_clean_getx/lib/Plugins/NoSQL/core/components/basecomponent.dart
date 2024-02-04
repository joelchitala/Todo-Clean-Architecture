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

// class CommandBlock<T> {
//   T? _reference;

//   Future<bool> Function(Function(T? ref) setRef)? _doFunction;
//   Future<bool> Function(T? ref)? _undoFunction;

//   void _setReference(T? ref) {
//     _reference = ref;
//   }

//   void setCommands({
//     required Future<bool> Function(Function(T? ref) setRef) doFunc,
//     required Future<bool> Function(T? ref) undoFunc,
//   }) {
//     _doFunction = doFunc;
//     _undoFunction = undoFunc;
//   }

//   Future<bool> execute() async {
//     if (_doFunction == null) return true;
//     return await _doFunction!(_setReference);
//   }

//   Future<bool> undo() async {
//     if (_undoFunction == null) return true;
//     return await _undoFunction!(_reference);
//   }
// }

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

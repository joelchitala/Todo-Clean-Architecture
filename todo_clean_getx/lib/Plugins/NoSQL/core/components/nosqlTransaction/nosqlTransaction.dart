import '../../dataStructures/BiLinkedList.dart';
import '../commands/commandBlock.dart';
import 'nosqlTransactionManager.dart';

class NoSQLTransaction {
  NoSQLTransactionManager _transactionManager = NoSQLTransactionManager();
  bool _open = true;
  CommandBlock? _currentBlock;
  Future<void> Function()? _executeFunction;
  BidirectionalLinkedList<CommandBlock> _blocks = BidirectionalLinkedList();

  Future<bool> initialize() async {
    return _transactionManager.setCurrentTransaction(this);
  }

  Future<bool> addBlock(CommandBlock block) async {
    if (_open) {
      _blocks.insert(data: block);
      return true;
    }
    if (_currentBlock != null) {
      bool res = await _currentBlock?.addInternalBlock(block) ?? false;
      return res;
    }

    return false;
  }

  Future<bool> setTransaction(Future<void> Function() function) async {
    try {
      _executeFunction = function;
      return true;
    } catch (e) {
      print(e);
    }
    return false;
  }

  Future<bool> rollback() async {
    try {
      _blocks.setCursor(index: _blocks.objects.length - 1);
      while (true) {
        var pointer = _blocks.currentPointer;

        if (pointer == null) break;
        var block = pointer.data;

        if (block != null) {
          await block.undo();
        }

        var regress = _blocks.regressCursor();

        if (!regress) break;
      }
      return true;
    } catch (e) {
      print(e);
    }

    return false;
  }

  Future<bool> execute() async {
    bool results = true;

    bool isRollback = false;

    try {
      if (!await initialize()) return false;

      if (_executeFunction != null) await _executeFunction!();
      _open = false;

      while (true) {
        var pointer = _blocks.currentPointer;

        if (pointer == null) break;

        var block = pointer.data;

        _currentBlock = block;

        if (block != null) {
          var res = isRollback ? await block.undo() : await block.execute();
          if (!res) {
            results = false;
          }
        }

        if ((block == null || !results) && !isRollback) {
          isRollback = true;
          continue;
        }
        var progress =
            isRollback ? _blocks.regressCursor() : _blocks.progressCursor();

        if (!progress) break;
      }
      _currentBlock = null;
    } catch (e) {
      print(e);
    }

    await dispose();
    return results;
  }

  Future<bool> dispose() async {
    return await _transactionManager.setCurrentTransaction(null);
  }
}

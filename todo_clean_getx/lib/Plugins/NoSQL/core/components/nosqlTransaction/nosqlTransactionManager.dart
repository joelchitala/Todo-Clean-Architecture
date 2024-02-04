import '../commands/commandBlock.dart';
import 'nosqlTransaction.dart';

class NoSQLTransactionManager {
  NoSQLTransaction? currentTransaction;

  NoSQLTransactionManager._();
  // static final _instance = NoSQLTransactionManager._();
  static NoSQLTransactionManager? _instance;

  factory NoSQLTransactionManager() {
    _instance ??= NoSQLTransactionManager._();
    return _instance!;
  }

  bool setCurrentTransaction(NoSQLTransaction? transaction) {
    if (currentTransaction == null && transaction != null) {
      currentTransaction = transaction;
      return true;
    }

    if (currentTransaction != null && transaction == null) {
      currentTransaction = null;
      return true;
    }

    return false;
  }

  Future<bool> addTransactionBlock(CommandBlock block) async {
    if (currentTransaction == null) return false;
    return await currentTransaction?.addBlock(block) ?? false;
  }
}

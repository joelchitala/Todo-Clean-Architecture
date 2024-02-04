import 'package:todo_clean_getx/Plugins/NoSQL/core/components/builders/queryBuilders/queryBuilder.dart';
import 'package:todo_clean_getx/Plugins/NoSQL/core/nosqlUtility.dart';
import 'package:todo_clean_getx/features/todo/domain/entities/todo.dart';

abstract class TodoRemoteDatabase {
  Future<Todo> add({required Todo todo});
  Future<Todo> edit({required Todo todo});
  Future<Todo> delete({required Todo todo});
  Future<List<Todo>> listTodos();
}

class TodoRemoteDatabaseImpl implements TodoRemoteDatabase {
  final String reference = "todos";
  final NoSQLUtility _noSQLUtility = NoSQLUtility();

  @override
  Future<Todo> add({required Todo todo}) async {
    await _noSQLUtility.insertDocument(
      reference: reference,
      data: todo.toJson(),
    );

    return todo;
  }

  @override
  Future<Todo> delete({required Todo todo}) async {
    await _noSQLUtility.removeDocument(
      reference: reference,
      query: QueryBuilder().eq(key: "id", values: [todo.id]),
    );

    return todo;
  }

  @override
  Future<Todo> edit({required Todo todo}) async {
    await _noSQLUtility.updateDocument(
      reference: reference,
      query: QueryBuilder().eq(key: "id", values: [todo.id]),
      data: todo.toJson(),
    );

    return todo;
  }

  @override
  Future<List<Todo>> listTodos() async {
    var results = await _noSQLUtility.getDocuments(
      reference: reference,
    );
  }
}

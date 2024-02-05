import 'dart:async';

import 'package:todo_clean_getx/Plugins/NoSQL/core/components/builders/queryBuilders/queryBuilder.dart';
import 'package:todo_clean_getx/Plugins/NoSQL/core/nosqlUtility.dart';
import 'package:todo_clean_getx/features/todo/domain/entities/todo.dart';

abstract class TodoRemoteDatabase {
  Future<Todo> add({required Todo todo});
  Future<Todo> edit({required Todo todo});
  Future<Todo> delete({required Todo todo});
  Stream<List<Todo>> listTodos();
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
  Stream<List<Todo>> listTodos() async* {
    var results = await _noSQLUtility.getDocumentStream(
      reference: reference,
    );

    yield* results.map(
      (documents) => documents
          .map(
            (document) => Todo.fromJson(document.fields),
          )
          .toList(),
    );
  }
}

Stream<List<T>> listToStream<T>(List<T> inputList) {
  final controller = StreamController<List<T>>();

  // Add the list to the stream
  controller.add(inputList);

  // Close the stream when done
  controller.close();

  // Return the stream
  return controller.stream;
}

import 'package:todo_clean_getx/features/todo/domain/entities/todo.dart';

abstract class TodoRepository {
  // Add TODO
  Future<Todo> add({required Todo todo});
  // Edit TODO
  Future<Todo> edit({required Todo todo});
  // Delete TODO
  Future<Todo> delete({required Todo todo});
  // Get All TODO
  Future<List<Todo>> getAll();
}

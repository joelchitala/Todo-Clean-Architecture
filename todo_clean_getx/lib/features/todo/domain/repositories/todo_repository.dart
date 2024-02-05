import 'package:dartz/dartz.dart';
import 'package:todo_clean_getx/features/todo/domain/entities/todo.dart';
import 'package:todo_clean_getx/shared/errors/failure.dart';

abstract class TodoRepository {
  // Add TODO
  Future<Either<Failure, Todo>> add({required Todo todo});
  // Edit TODO
  Future<Either<Failure, Todo>> edit({required Todo todo});
  // Delete TODO
  Future<Either<Failure, Todo>> delete({required Todo todo});
  // Get All TODO
  Future<Either<Failure, List<Todo>>> getAll();
}

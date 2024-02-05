import 'package:dartz/dartz.dart';
import 'package:todo_clean_getx/features/todo/data/database/todo_remote_database.dart';
import 'package:todo_clean_getx/features/todo/domain/entities/todo.dart';
import 'package:todo_clean_getx/features/todo/domain/repositories/todo_repository.dart';
import 'package:todo_clean_getx/shared/errors/failure.dart';

class TodoRepositoryImpl implements TodoRepository {
  final TodoRemoteDatabase remoteDatabase;

  TodoRepositoryImpl({required this.remoteDatabase});

  @override
  Future<Either<Failure, Todo>> add({required Todo todo}) async {
    try {
      final results = await remoteDatabase.add(todo: todo);
      return Right(results);
    } catch (e) {
      return Left(Failure(message: "Failed to add todo ${todo.id}"));
    }
  }

  @override
  Future<Either<Failure, Todo>> edit({required Todo todo}) async {
    try {
      final results = await remoteDatabase.edit(todo: todo);
      return Right(results);
    } catch (e) {
      return Left(Failure(message: "Failed to edit todo ${todo.id}"));
    }
  }

  @override
  Future<Either<Failure, Todo>> delete({required Todo todo}) async {
    try {
      final results = await remoteDatabase.delete(todo: todo);
      return Right(results);
    } catch (e) {
      return Left(Failure(message: "Failed to delete todo ${todo.id}"));
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> getAll() async {
    try {
      final results = await remoteDatabase.listTodos();
      return Right(results);
    } catch (e) {
      return Left(Failure(message: "Failed to get todos"));
    }
  }
}

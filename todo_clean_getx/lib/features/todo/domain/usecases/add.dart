import 'package:dartz/dartz.dart';
import 'package:todo_clean_getx/features/todo/domain/entities/todo.dart';
import 'package:todo_clean_getx/features/todo/domain/repositories/todo_repository.dart';
import 'package:todo_clean_getx/shared/errors/failure.dart';
import 'package:todo_clean_getx/shared/utils/usecase.dart';

class AddTodoUseCase implements UseCase<Todo, Params<Todo>> {
  final TodoRepository repository;

  AddTodoUseCase({required this.repository});

  @override
  Future<Either<Failure, Todo>> call(Params todo) async {
    return await repository.add(todo: todo.data);
  }
}

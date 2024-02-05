import 'package:dartz/dartz.dart';
import 'package:todo_clean_getx/features/todo/domain/entities/todo.dart';
import 'package:todo_clean_getx/features/todo/domain/repositories/todo_repository.dart';
import 'package:todo_clean_getx/shared/errors/failure.dart';
import 'package:todo_clean_getx/shared/utils/usecase.dart';

class ListTodoUseCase implements UseCase<Stream<List<Todo>>, NoParams> {
  final TodoRepository repository;

  ListTodoUseCase({required this.repository});

  @override
  Future<Either<Failure, Stream<List<Todo>>>> call(NoParams noParams) {
    return repository.getAll();
  }
}

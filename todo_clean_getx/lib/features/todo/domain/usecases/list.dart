import 'package:dartz/dartz.dart';
import 'package:todo_clean_getx/features/todo/domain/entities/todo.dart';
import 'package:todo_clean_getx/features/todo/domain/repositories/todo_repository.dart';
import 'package:todo_clean_getx/shared/errors/failure.dart';
import 'package:todo_clean_getx/shared/utils/usecase.dart';

class EditTodoUseCase implements UseCase<List<Todo>, NoParams> {
  final TodoRepository repository;

  EditTodoUseCase({required this.repository});

  @override
  Future<Either<Failure, List<Todo>>> call(NoParams noParams) async {
    return await repository.getAll();
  }
}

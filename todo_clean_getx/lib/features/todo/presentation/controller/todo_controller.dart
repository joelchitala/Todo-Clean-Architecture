import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todo_clean_getx/features/todo/domain/entities/todo.dart';
import 'package:todo_clean_getx/features/todo/domain/usecases/add.dart';
import 'package:todo_clean_getx/features/todo/domain/usecases/delete.dart';
import 'package:todo_clean_getx/features/todo/domain/usecases/edit.dart';
import 'package:todo_clean_getx/features/todo/domain/usecases/list.dart';
import 'package:todo_clean_getx/shared/utils/tools.dart';
import 'package:todo_clean_getx/shared/utils/usecase.dart';

class TodoController extends GetxController {
  var formKey = GlobalKey<FormState>();
  var titleController = TextEditingController();
  var descriptionController = TextEditingController();

  final AddTodoUseCase addTodoUseCase;
  final EditTodoUseCase editTodoUseCase;
  final DeleteTodoUseCase deleteTodoUseCase;
  final ListTodoUseCase listTodoUseCase;

  TodoController({
    required this.addTodoUseCase,
    required this.editTodoUseCase,
    required this.deleteTodoUseCase,
    required this.listTodoUseCase,
  });

  Future<void> add() async {
    final results = await addTodoUseCase.call(
      Params(
        Todo(
          id: generateRandomString(16),
          text: titleController.text.trim(),
          description: descriptionController.text.trim(),
        ),
      ),
    );

    results.fold(
      (failure) {
        Get.snackbar("Error", failure.message);
      },
      (todo) {
        Get.snackbar("Success", "Todo added successfully");
        clear();
      },
    );
  }

  void clear() {
    titleController.text = "";
    descriptionController.text = "";
  }

  Stream<List<Todo>> listTodo() async* {
    final results = await listTodoUseCase(NoParams());

    yield* results.fold((failure) {
      Get.snackbar("Error", failure.message);
      return Stream.value([]);
    }, (todos) {
      return todos;
    });
  }
}

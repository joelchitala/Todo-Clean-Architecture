import 'package:get/get.dart';
import 'package:todo_clean_getx/features/todo/data/database/todo_remote_database.dart';
import 'package:todo_clean_getx/features/todo/data/repositories/todo_repository_impl.dart';
import 'package:todo_clean_getx/features/todo/domain/repositories/todo_repository.dart';
import 'package:todo_clean_getx/features/todo/domain/usecases/add.dart';
import 'package:todo_clean_getx/features/todo/domain/usecases/delete.dart';
import 'package:todo_clean_getx/features/todo/domain/usecases/edit.dart';
import 'package:todo_clean_getx/features/todo/domain/usecases/list.dart';
import 'package:todo_clean_getx/features/todo/presentation/controller/todo_controller.dart';

class TodoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TodoRemoteDatabase>(() => TodoRemoteDatabaseImpl());
    Get.lazyPut<TodoRepository>(
        () => TodoRepositoryImpl(remoteDatabase: Get.find()));
    Get.lazyPut(() => AddTodoUseCase(repository: Get.find()));
    Get.lazyPut(() => EditTodoUseCase(repository: Get.find()));
    Get.lazyPut(() => DeleteTodoUseCase(repository: Get.find()));
    Get.lazyPut(() => ListTodoUseCase(repository: Get.find()));
    Get.lazyPut(
      () => TodoController(
        addTodoUseCase: Get.find(),
        editTodoUseCase: Get.find(),
        deleteTodoUseCase: Get.find(),
        listTodoUseCase: Get.find(),
      ),
    );
  }
}

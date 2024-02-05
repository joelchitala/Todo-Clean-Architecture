import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todo_clean_getx/features/todo/domain/entities/todo.dart';
import 'package:todo_clean_getx/features/todo/presentation/controller/todo_controller.dart';

class HomePage extends GetView<TodoController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(),
      body: StreamBuilder(
        stream: controller.listTodo(),
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return const Center(
              child: Text("No Todo available"),
            );
          }
          final data = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                var todo = data[index];

                return Container(
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          offset: const Offset(1, 2),
                          color: const Color(0xff121212).withOpacity(0.125)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(todo.text),
                              Text(todo.description),
                            ],
                          )),
                      Expanded(
                          child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) {
                                  controller.titleController.text = todo.text;
                                  controller.descriptionController.text =
                                      todo.description;
                                  return SizedBox(
                                    width: double.infinity,
                                    height: MediaQuery.of(context).size.height *
                                        0.6,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Form(
                                          key: controller.formKey,
                                          child: Column(
                                            children: [
                                              TextFormField(
                                                controller:
                                                    controller.titleController,
                                                validator: (value) {
                                                  return value!.isEmpty
                                                      ? "Title is Required"
                                                      : null;
                                                },
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: "Title",
                                                ),
                                              ),
                                              TextFormField(
                                                controller: controller
                                                    .descriptionController,
                                                validator: (value) {
                                                  return value!.isEmpty
                                                      ? "Description is Required"
                                                      : null;
                                                },
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: "Description",
                                                ),
                                              ),
                                              SizedBox(
                                                width: double.maxFinite,
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    if (!controller
                                                        .formKey.currentState!
                                                        .validate()) return;
                                                    controller.editTodo(todo);
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text("Add"),
                                                ),
                                              )
                                            ],
                                          )),
                                    ),
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            onPressed: () async {
                              await controller.deleteTodo(todo);
                            },
                            icon: const Icon(Icons.delete),
                          ),
                        ],
                      ))
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) {
              return SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Form(
                      key: controller.formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: controller.titleController,
                            validator: (value) {
                              return value!.isEmpty
                                  ? "Title is Required"
                                  : null;
                            },
                            decoration: const InputDecoration(
                              labelText: "Title",
                            ),
                          ),
                          TextFormField(
                            controller: controller.descriptionController,
                            validator: (value) {
                              return value!.isEmpty
                                  ? "Description is Required"
                                  : null;
                            },
                            decoration: const InputDecoration(
                              labelText: "Description",
                            ),
                          ),
                          SizedBox(
                            width: double.maxFinite,
                            child: ElevatedButton(
                              onPressed: () {
                                if (!controller.formKey.currentState!
                                    .validate()) return;
                                controller.add();
                                Navigator.pop(context);
                              },
                              child: const Text("Add"),
                            ),
                          )
                        ],
                      )),
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

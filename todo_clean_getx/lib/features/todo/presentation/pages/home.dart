import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }
          final data = snapshot.data!;
          return ListView.separated(
            itemCount: data.length,
            itemBuilder: (context, index) {
              var todo = data[index];
              return ListTile(
                title: Text(todo.text),
                subtitle: Text(todo.description),
              );
            },
            separatorBuilder: (context, index) {
              return const SizedBox(height: 8.0);
            },
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

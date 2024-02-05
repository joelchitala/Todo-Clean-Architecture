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
      body: Obx(() {
        return Center(
          child: Text("Count "),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) {
              return Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
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
                                controller.clear();
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

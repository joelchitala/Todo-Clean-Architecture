import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todo_clean_getx/features/todo/presentation/bindings/todo_binding.dart';
import 'package:todo_clean_getx/features/todo/presentation/pages/home.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      getPages: [
        GetPage(name: "/", page: () => HomePage(), binding: TodoBinding()),
      ],
    );
  }
}

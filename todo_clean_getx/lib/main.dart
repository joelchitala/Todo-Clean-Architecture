import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todo_clean_getx/Plugins/NoSQL/core/components/nosqlTransaction/nosqlTransaction.dart';
import 'package:todo_clean_getx/Plugins/NoSQL/core/nosqlManager.dart';
import 'package:todo_clean_getx/Plugins/NoSQL/core/nosqlUtility.dart';
import 'package:todo_clean_getx/features/todo/presentation/bindings/todo_binding.dart';
import 'package:todo_clean_getx/features/todo/presentation/pages/home.dart';

void initialize() async {
  NoSQLUtility noSQLUtility = NoSQLUtility();

  NoSQLTransaction noSQLTransaction = NoSQLTransaction();

  await noSQLTransaction.setTransaction(() async {
    await noSQLUtility.createDatabase(name: "todoDB");
    await noSQLUtility.setCurrentDatabase(name: "todoDB");
    await noSQLUtility.createCollection(reference: "todos");
  });

  await noSQLTransaction.execute();
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initialize();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      getPages: [
        GetPage(
            name: "/", page: () => const HomePage(), binding: TodoBinding()),
      ],
    );
  }
}

import 'dart:convert';
import 'dart:io';

bool createDirectory(String path) {
  Directory newDirectory = Directory(path);

  if (!newDirectory.existsSync()) {
    newDirectory.createSync(recursive: true);
    print('Directory created successfully.');
    return true;
  } else {
    print('Directory already exists.');
    return false;
  }
}

Future<Map<String, dynamic>?> readJsonFile(String filePath) async {
  try {
    File file = File(filePath);
    if (await file.exists()) {
      String contents = await file.readAsString();
      Map<String, dynamic> jsonData = jsonDecode(contents);
      return jsonData;
    } else {
      throw Exception("File not found");
    }
  } catch (e) {
    print("Error reading JSON file: $e");
    return null;
  }
}

Future<bool> writeJsonFile(
    String filePath, Map<dynamic, dynamic> jsonData) async {
  try {
    File file = File(filePath);
    String jsonString = jsonEncode(jsonData);
    await file.writeAsString(jsonString);
    return true;
  } catch (e) {
    print("Error writing JSON file: $e");
    return false;
  }
}

class Todo {
  String id, text, description;

  Todo({
    required this.id,
    required this.text,
    required this.description,
  });

  factory Todo.fromJson(Map<String, dynamic> data) {
    return Todo(
      id: data["id"],
      text: data["text"],
      description: data["description"],
    );
  }

  factory Todo.update(Todo todo, Map<String, dynamic> data) {
    return Todo(
      id: todo.id,
      text: data["text"] ?? todo.text,
      description: data["description"] ?? todo.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "text": text,
      "description": description,
    };
  }
}

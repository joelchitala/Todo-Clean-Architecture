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

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "text": text,
      "description": description,
    };
  }
}

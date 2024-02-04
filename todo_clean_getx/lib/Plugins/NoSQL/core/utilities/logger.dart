import 'fileoperations.dart';
import 'utils.dart';

class LogEntries {
  DateTime? timestamp, closeTimestamp;

  Map<String, dynamic> _entries = {};

  LogEntries({this.timestamp, this.closeTimestamp}) {
    timestamp = timestamp ?? DateTime.now();
  }

  factory LogEntries.fromJson(Map<String, dynamic> data) {
    LogEntries logEntries = LogEntries(
      timestamp: DateTime.tryParse(data["timestamp"]),
      closeTimestamp: DateTime.tryParse(data["closeTimestamp"]),
    );

    logEntries._entries = data["entries"] ?? {};

    return logEntries;
  }

  Map<String, dynamic> toJson() => {
        "timestamp": timestamp?.toIso8601String(),
        "closeTimestamp": closeTimestamp?.toIso8601String(),
        "entries": _entries,
      };
}

class Logger {
  final Map<String, LogEntries> _entries = {};
  final LogEntries currentEntry = LogEntries();
  String path = "./log.json";

  Logger._();

  static final Logger _instance = Logger._();

  factory Logger() {
    return _instance;
  }

  Future<void> initialize() async {
    String genericError = "Failed to load logs";

    Map<String, dynamic>? content = await readJsonFile(path);
    if (content == null) {
      print_and_log("$genericError, no content found in path -> $path");
      return;
    }

    try {
      if (content["entries"] != null) {
        content["entries"].forEach((key, value) {
          LogEntries logEntries = LogEntries.fromJson(value);
          _entries.addAll({key: logEntries});
        });
      }
    } catch (e) {
      print_and_log(
          "$genericError, failed to initialize logger, error -> $e occured");
    }
  }

  void logger_print(String message) {
    try {
      String format = "${generateFullTimeStamp()} -> $message";
      print(format);
    } catch (e) {
      print(e);
    }
  }

  void logger_log(String message) {
    try {
      currentEntry._entries.addAll({DateTime.now().toIso8601String(): message});
    } catch (e) {
      print(e);
    }
  }

  void print_and_log(String message) {
    logger_print(message);
    logger_log(message);
  }

  Future<bool> commit() async {
    bool results = true;
    String genericError = "Failed to save logs";

    currentEntry.closeTimestamp = DateTime.now();

    results = await writeJsonFile(path, toJson());

    if (!results) print_and_log("$genericError, an error has occured");
    return results;
  }

  Map<String, dynamic> toJson() {
    var temp_entries = {};

    _entries.forEach((key, value) {
      temp_entries.addAll({key: value.toJson()});
    });

    temp_entries.addAll(
        {currentEntry.timestamp!.toIso8601String(): currentEntry.toJson()});
    return {
      "entries": temp_entries,
    };
  }
}

class Logging {
  final Logger _log = Logger();
  get log_entries => _log._entries;

  get logger_log => _log.logger_log;
  get print_and_log => _log.print_and_log;

  set log(String message) => _log.logger_log(message);
}

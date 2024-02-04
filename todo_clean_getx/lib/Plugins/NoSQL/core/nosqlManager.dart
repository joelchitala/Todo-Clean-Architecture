import 'components/database.dart';
import 'utilities/fileoperations.dart';
import 'utilities/logger.dart';

class NoSQLManager extends Logging {
  double _version = 3.0;
  DateTime? _timestamp;
  String databasePath = "database.json";
  final String name = "NoSQLManager Class";
  final String type = "NOSQLMANAGER";
  bool caseSensitive = false;
  Map<String, Database> _databases = {};

  Database? _currentDatabase;

  //Select whether database is only stored in memory or not
  bool inMemoryOnlyMode = false;
  NoSQLManager._();

  static final _instance = NoSQLManager._();

  factory NoSQLManager() => _instance;

  Map<String, Database> get databases => _databases;

  Database? get currentDatabase => _currentDatabase;

  set currentDatabase(Database? database) => _currentDatabase = database;

  // Load data from file to memory
  Future<void> initialize() async {
    try {
      String genericError = "Failed to initialize database";

      if (inMemoryOnlyMode) {
        print_and_log("In memory mode selected");
        return;
      }

      Map<String, dynamic>? content = await readJsonFile(databasePath);

      if (content == null) {
        print_and_log(
            "$genericError, no content found in path -> $databasePath");
        return;
      }

      _version = content["version"] ?? _version;

      _timestamp = DateTime.tryParse(content["timestamp"]);

      Map<String, dynamic>? databases = content["databases"];

      databases?.forEach((key, value) {
        _databases.addAll({key: Database.fromJson(value)});
      });
    } catch (e) {
      print_and_log("Error -> $e occured when initializing database");
      return;
    }

    await Logger().initialize();
  }

  // Save data in memory to file
  Future<bool> commit() async {
    try {
      await writeJsonFile(databasePath, toJson());
    } catch (e) {
      print_and_log(
          "Failed to write data to path: $databasePath . The following error $e occured");
      return false;
    }

    await Logger().commit();
    return true;
  }

  // To Json
  Map<String, dynamic> toJson() {
    Map<String, Map> temp_entries = {};
    _databases.forEach((key, value) {
      temp_entries.addAll({key: value.toJson()});
    });

    return {
      "version": _version,
      "name": name,
      "type": type,
      "timestamp": _timestamp == null
          ? DateTime.now().toIso8601String()
          : _timestamp?.toIso8601String(),
      "number_of_databases": _databases.length,
      "databases": temp_entries,
    };
  }
}

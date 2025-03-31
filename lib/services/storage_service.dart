import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/command_storage.dart';

class StorageService {
  static const String boxName = 'command_box';
  static const String storageKey = 'last_command';

  Future<void> saveCommand({
    required String commandText,
    required String jsonResult,
    required bool isCommand,
  }) async {
    final box = Hive.box<CommandStorage>(boxName);
    final storage = CommandStorage(
      commandText: commandText,
      jsonResult: jsonResult,
      lastExecutionTime: DateTime.now(),
      wasCommand: isCommand,
    );
    await box.put(storageKey, storage);
  }

  CommandStorage? getLastCommand() {
    final box = Hive.box<CommandStorage>(boxName);
    return box.get(storageKey);
  }

  String getFormattedTimestamp() {
    final storage = getLastCommand();
    if (storage == null || storage.lastExecutionTime == null) {
      return "No Previous Execution";
    }

    final dateFormat = DateFormat("MMMM d, yyyy h:mm:ss a 'ET'");
    final timestamp = dateFormat.format(storage.lastExecutionTime!);
    final prefix = storage.wasCommand == true
        ? "Last Custom Command: "
        : "Last Get Conf: ";

    return "$prefix$timestamp";
  }
}

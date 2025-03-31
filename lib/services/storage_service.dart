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
    try {
      final box = Hive.box<CommandStorage>(boxName);
      final storage = CommandStorage(
        commandText: commandText,
        jsonResult: jsonResult,
        lastExecutionTime: DateTime.now(),
        wasCommand: isCommand,
      );
      await box.put(storageKey, storage);
      print(
          'Saved to Hive - Command: $commandText, Result length: ${jsonResult.length}');
    } catch (e) {
      print('Error saving to Hive: $e');
    }
  }

  CommandStorage? getLastCommand() {
    try {
      final box = Hive.box<CommandStorage>(boxName);
      final storage = box.get(storageKey);
      if (storage != null) {
        print(
            'Retrieved from Hive - Command: ${storage.commandText}, Result exists: ${storage.jsonResult != null}');
      } else {
        print('No stored command found in Hive');
      }
      return storage;
    } catch (e) {
      print('Error retrieving from Hive: $e');
      return null;
    }
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

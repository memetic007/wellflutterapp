import 'package:hive_flutter/hive_flutter.dart';

class HiveBoxService {
  static const String commandBoxName = 'command_box';
  static const String lastCommandKey = 'last_command';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(commandBoxName);
  }

  static Box _getCommandBox() {
    return Hive.box(commandBoxName);
  }

  static Future<void> saveLastCommand(String command) async {
    final box = _getCommandBox();
    await box.put(lastCommandKey, command);
  }

  static String? getLastCommand() {
    final box = _getCommandBox();
    return box.get(lastCommandKey) as String?;
  }
}

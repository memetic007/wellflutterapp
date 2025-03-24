import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class HiveBoxService {
  static const String commandBoxName = 'command_box';
  static const String lastCommandKey = 'last_command';
  static const String lastJsonResponseKey = 'last_json_response';

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

  static Future<void> saveLastJsonResponse(dynamic jsonData) async {
    final box = _getCommandBox();
    // Convert to string to ensure we can store it
    final jsonString = jsonEncode(jsonData);
    await box.put(lastJsonResponseKey, jsonString);
  }

  static dynamic getLastJsonResponse() {
    final box = _getCommandBox();
    final jsonString = box.get(lastJsonResponseKey) as String?;
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      print('Error decoding stored JSON: $e');
      return null;
    }
  }
}

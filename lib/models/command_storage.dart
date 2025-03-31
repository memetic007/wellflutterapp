import 'package:hive/hive.dart';

part 'command_storage.g.dart';

@HiveType(typeId: 0)
class CommandStorage extends HiveObject {
  @HiveField(0)
  String? commandText;

  @HiveField(1)
  String? jsonResult;

  @HiveField(2)
  DateTime? lastExecutionTime;

  @HiveField(3)
  bool? wasCommand; // true for Command, false for Get Conf

  CommandStorage({
    this.commandText,
    this.jsonResult,
    this.lastExecutionTime,
    this.wasCommand,
  });
}

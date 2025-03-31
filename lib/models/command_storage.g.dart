// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command_storage.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CommandStorageAdapter extends TypeAdapter<CommandStorage> {
  @override
  final int typeId = 0;

  @override
  CommandStorage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CommandStorage(
      commandText: fields[0] as String?,
      jsonResult: fields[1] as String?,
      lastExecutionTime: fields[2] as DateTime?,
      wasCommand: fields[3] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, CommandStorage obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.commandText)
      ..writeByte(1)
      ..write(obj.jsonResult)
      ..writeByte(2)
      ..write(obj.lastExecutionTime)
      ..writeByte(3)
      ..write(obj.wasCommand);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommandStorageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

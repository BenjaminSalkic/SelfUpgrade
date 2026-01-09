import 'package:hive/hive.dart';
import '../journal_entry.dart';

class JournalEntryAdapter extends TypeAdapter<JournalEntry> {
  @override
  final int typeId = 0;

  @override
  JournalEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JournalEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      content: fields[2] as String,
      linkedEntryIds: (fields[3] as List).cast<String>(),
      goalResponses: (fields[4] as Map).cast<String, String>(),
      goalTags: fields[7] != null ? (fields[7] as List).cast<String>() : [],
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, JournalEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.linkedEntryIds)
      ..writeByte(4)
      ..write(obj.goalResponses)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.goalTags);
  }
}

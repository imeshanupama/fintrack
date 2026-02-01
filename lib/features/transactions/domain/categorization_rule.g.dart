// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categorization_rule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategorizationRuleAdapter extends TypeAdapter<CategorizationRule> {
  @override
  final int typeId = 10;

  @override
  CategorizationRule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategorizationRule(
      id: fields[0] as String,
      pattern: fields[1] as String,
      categoryId: fields[2] as String,
      confidence: fields[3] as double,
      usageCount: fields[4] as int,
      createdAt: fields[5] as DateTime,
      lastUsedAt: fields[6] as DateTime,
      isUserDefined: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CategorizationRule obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.pattern)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.confidence)
      ..writeByte(4)
      ..write(obj.usageCount)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.lastUsedAt)
      ..writeByte(7)
      ..write(obj.isUserDefined);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategorizationRuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

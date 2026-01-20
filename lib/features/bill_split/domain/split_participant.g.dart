// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'split_participant.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SplitParticipantAdapter extends TypeAdapter<SplitParticipant> {
  @override
  final int typeId = 9;

  @override
  SplitParticipant read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SplitParticipant(
      name: fields[0] as String,
      amount: fields[1] as double,
      isPaid: fields[2] as bool,
      paidDate: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SplitParticipant obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.isPaid)
      ..writeByte(3)
      ..write(obj.paidDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitParticipantAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

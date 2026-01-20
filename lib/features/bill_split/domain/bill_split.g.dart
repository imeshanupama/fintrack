// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_split.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BillSplitAdapter extends TypeAdapter<BillSplit> {
  @override
  final int typeId = 10;

  @override
  BillSplit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BillSplit(
      id: fields[0] as String,
      title: fields[1] as String,
      totalAmount: fields[2] as double,
      currencyCode: fields[3] as String,
      date: fields[4] as DateTime,
      participants: (fields[5] as List).cast<SplitParticipant>(),
      myShare: fields[6] as double?,
      transactionId: fields[7] as String?,
      receiptPath: fields[8] as String?,
      note: fields[9] as String?,
      createdAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BillSplit obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.totalAmount)
      ..writeByte(3)
      ..write(obj.currencyCode)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.participants)
      ..writeByte(6)
      ..write(obj.myShare)
      ..writeByte(7)
      ..write(obj.transactionId)
      ..writeByte(8)
      ..write(obj.receiptPath)
      ..writeByte(9)
      ..write(obj.note)
      ..writeByte(10)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillSplitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

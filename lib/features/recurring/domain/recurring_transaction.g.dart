// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringTransactionAdapter extends TypeAdapter<RecurringTransaction> {
  @override
  final int typeId = 5;

  @override
  RecurringTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringTransaction(
      id: fields[0] as String,
      amount: fields[1] as double,
      currencyCode: fields[2] as String,
      categoryId: fields[3] as String,
      accountId: fields[4] as String,
      note: fields[5] as String,
      type: fields[6] as TransactionType,
      interval: fields[7] as String,
      nextDueDate: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringTransaction obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.currencyCode)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.accountId)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.interval)
      ..writeByte(8)
      ..write(obj.nextDueDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exchange_rate.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExchangeRateAdapter extends TypeAdapter<ExchangeRate> {
  @override
  final int typeId = 12;

  @override
  ExchangeRate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExchangeRate(
      baseCurrency: fields[0] as String,
      targetCurrency: fields[1] as String,
      rate: fields[2] as double,
      lastUpdated: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ExchangeRate obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.baseCurrency)
      ..writeByte(1)
      ..write(obj.targetCurrency)
      ..writeByte(2)
      ..write(obj.rate)
      ..writeByte(3)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExchangeRateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

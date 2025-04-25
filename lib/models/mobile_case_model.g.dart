// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mobile_case_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MobileCaseModelAdapter extends TypeAdapter<MobileCaseModel> {
  @override
  final int typeId = 0;

  @override
  MobileCaseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MobileCaseModel(
      id: fields[0] as String,
      brand: fields[1] as String,
      model: fields[2] as String,
      price: fields[3] as double,
      quantity: fields[4] as int,
      imageUrl: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MobileCaseModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.brand)
      ..writeByte(2)
      ..write(obj.model)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.imageUrl)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MobileCaseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

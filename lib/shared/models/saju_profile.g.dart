// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saju_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SajuProfileAdapter extends TypeAdapter<SajuProfile> {
  @override
  final int typeId = 0;

  @override
  SajuProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SajuProfile(
      name: fields[0] as String,
      birthDate: fields[1] as DateTime,
      birthHour: fields[2] as int,
      gender: fields[3] as String,
      createdAt: fields[4] as DateTime,
      birthMinute: fields[5] as int? ?? 0,           // 신규 (기존 데이터 호환)
      birthLongitude: fields[6] as double?,           // 신규 (기존 데이터 null)
    );
  }

  @override
  void write(BinaryWriter writer, SajuProfile obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.birthDate)
      ..writeByte(2)
      ..write(obj.birthHour)
      ..writeByte(3)
      ..write(obj.gender)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.birthMinute)
      ..writeByte(6)
      ..write(obj.birthLongitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SajuProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

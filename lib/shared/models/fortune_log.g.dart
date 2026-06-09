// GENERATED CODE - DO NOT MODIFY BY HAND
// 수동 관리 — build_runner 미사용

part of 'fortune_log.dart';

class FortuneLogAdapter extends TypeAdapter<FortuneLog> {
  @override
  final int typeId = 1;

  @override
  FortuneLog read(BinaryReader reader) {
    final numOfFields = reader.readByte() as int;
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte() as int: reader.read(),
    };
    return FortuneLog()
      ..date         = fields[0] as DateTime
      ..dailyScore   = fields[1] as int
      ..dayGanJi     = fields[2] as String
      ..luckyDir     = fields[3] as String
      ..mainOehaeng  = fields[4] as String
      ..profileId    = fields[5] as String
      ..seWunScore   = (fields[6] as num?)?.toInt() ?? 0;
  }

  @override
  void write(BinaryWriter writer, FortuneLog obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.dailyScore)
      ..writeByte(2)
      ..write(obj.dayGanJi)
      ..writeByte(3)
      ..write(obj.luckyDir)
      ..writeByte(4)
      ..write(obj.mainOehaeng)
      ..writeByte(5)
      ..write(obj.profileId)
      ..writeByte(6)
      ..write(obj.seWunScore);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FortuneLogAdapter && other.typeId == typeId;

  @override
  int get hashCode => typeId.hashCode;
}

import 'package:hive/hive.dart';

part 'saju_profile.g.dart';

@HiveType(typeId: 0)
class SajuProfile extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  late DateTime birthDate;

  @HiveField(2)
  late int birthHour;

  @HiveField(3)
  late String gender; // '남' or '여'

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  int birthMinute;        // 출생 분(0~59), 기본값 0

  @HiveField(6)
  double? birthLongitude; // 진태양시 보정용 경도 (null = 보정 없음)

  SajuProfile({
    required this.name,
    required this.birthDate,
    required this.birthHour,
    required this.gender,
    DateTime? createdAt,
    this.birthMinute = 0,
    this.birthLongitude,
  }) : createdAt = createdAt ?? DateTime.now();

  String get birthHourLabel {
    if (birthHour == 25) return '모름';
    return '${birthHour.toString().padLeft(2, '0')}:00';
  }

  String get genderEmoji => gender == '남' ? '👨' : '👩';

  String get displayAge {
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    return '$age세';
  }
}

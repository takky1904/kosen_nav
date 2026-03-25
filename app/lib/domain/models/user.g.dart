// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: json['id'] as String,
  kosenName: json['kosenName'] as String?,
  grade: (json['grade'] as num?)?.toInt(),
  courseId: json['courseId'] as String?,
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'kosenName': instance.kosenName,
  'grade': instance.grade,
  'courseId': instance.courseId,
};

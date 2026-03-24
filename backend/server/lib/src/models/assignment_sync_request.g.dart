// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignment_sync_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssignmentSyncRequest _$AssignmentSyncRequestFromJson(
        Map<String, dynamic> json) =>
    AssignmentSyncRequest(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      dueDateTime: json['dueDateTime'] == null
          ? null
          : DateTime.parse(json['dueDateTime'] as String),
      content: json['content'] as String?,
    );

Map<String, dynamic> _$AssignmentSyncRequestToJson(
        AssignmentSyncRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'dueDateTime': instance.dueDateTime?.toIso8601String(),
      'content': instance.content,
    };

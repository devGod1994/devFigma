// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spacer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Spacer _$SpacerFromJson(Map<String, dynamic> json) {
  return Spacer(
    json['topLeftCorner'],
    json['bottomRightCorner'],
    json['UUID'] as String,
    flex: json['flex'] as int,
  )
    ..subsemantic = json['subsemantic'] as String
    ..child = json['child']
    ..size = json['size'] as Map<String, dynamic>
    ..borderInfo = json['borderInfo'] as Map<String, dynamic>
    ..alignment = json['alignment'] as Map<String, dynamic>
    ..name = json['name'] as String
    ..color = json['color'] as String;
}

Map<String, dynamic> _$SpacerToJson(Spacer instance) => <String, dynamic>{
      'subsemantic': instance.subsemantic,
      'child': instance.child,
      'topLeftCorner': instance.topLeftCorner,
      'bottomRightCorner': instance.bottomRightCorner,
      'size': instance.size,
      'borderInfo': instance.borderInfo,
      'alignment': instance.alignment,
      'name': instance.name,
      'color': instance.color,
      'flex': instance.flex,
      'UUID': instance.UUID,
    };

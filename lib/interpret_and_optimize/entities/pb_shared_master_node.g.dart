// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pb_shared_master_node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PBSharedMasterNode _$PBSharedMasterNodeFromJson(Map<String, dynamic> json) {
  return PBSharedMasterNode(
    json['originalRef'],
    json['SYMBOL_ID'] as String,
    json['name'] as String,
    json['topLeftCorner'] == null
        ? null
        : Point.fromJson(json['topLeftCorner'] as Map<String, dynamic>),
    json['bottomRightCorner'] == null
        ? null
        : Point.fromJson(json['bottomRightCorner'] as Map<String, dynamic>),
  )
    ..subsemantic = json['subsemantic'] as String
    ..child = json['child']
    ..size = json['size'] as Map<String, dynamic>
    ..borderInfo = json['borderInfo'] as Map<String, dynamic>
    ..alignment = json['alignment'] as Map<String, dynamic>
    ..color = json['color'] as String
    ..UUID = json['UUID'] as String
    ..parametersDefinition = (json['parametersDefinition'] as List)
        ?.map((e) => e == null
            ? null
            : PBSymbolMasterParameter.fromJson(e as Map<String, dynamic>))
        ?.toList();
}

Map<String, dynamic> _$PBSharedMasterNodeToJson(PBSharedMasterNode instance) =>
    <String, dynamic>{
      'subsemantic': instance.subsemantic,
      'child': instance.child,
      'topLeftCorner': instance.topLeftCorner,
      'bottomRightCorner': instance.bottomRightCorner,
      'size': instance.size,
      'borderInfo': instance.borderInfo,
      'alignment': instance.alignment,
      'color': instance.color,
      'UUID': instance.UUID,
      'originalRef': instance.originalRef,
      'SYMBOL_ID': instance.SYMBOL_ID,
      'name': instance.name,
      'parametersDefinition': instance.parametersDefinition,
    };

import 'dart:io';

import 'package:parabeac_core/controllers/main_info.dart';
import 'package:parabeac_core/design_logic/design_node.dart';
import 'package:parabeac_core/design_logic/pb_style.dart';
import 'package:parabeac_core/input/helper/azure_asset_service.dart';
import 'package:parabeac_core/input/sketch/entities/objects/frame.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/inherited_bitmap.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_context.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_intermediate_node.dart';

import 'abstract_design_node_factory.dart';

class Vector implements DesignNodeFactory, DesignNode {
  @override
  String pbdfType = 'vector';

  var layoutAlign;

  var constraints;

  var size;

  var strokes;

  var strokeWeight;

  var strokeAlign;

  var styles;

  var fillsList;

  Vector({
    String name,
    bool visible,
    String type,
    pluginData,
    sharedPluginData,
    this.layoutAlign,
    this.constraints,
    Frame this.boundaryRectangle,
    this.size,
    this.strokes,
    this.strokeWeight,
    this.strokeAlign,
    this.styles,
    this.fillsList,
    String UUID,
    pbdfType,
  });

  @override
  DesignNode createDesignNode(Map<String, dynamic> json) => fromPBDF(json);

  DesignNode fromPBDF(Map<String, dynamic> json) {
    return Vector(
      name: json['name'] as String,
      type: json['type'] as String,
      pluginData: json['pluginData'],
      sharedPluginData: json['sharedPluginData'],
      layoutAlign: json['layoutAlign'] as String,
      constraints: json['constraints'],
      boundaryRectangle: json['absoluteBoundingBox'] == null
          ? null
          : Frame.fromJson(json['absoluteBoundingBox'] as Map<String, dynamic>),
      size: json['size'],
      strokes: json['strokes'],
      strokeWeight: (json['strokeWeight'] as num)?.toDouble(),
      strokeAlign: json['strokeAlign'] as String,
      styles: json['styles'],
      fillsList: json['fills'] as List,
      UUID: json['id'] as String,
      pbdfType: json['pbdfType'],
    )..type = json['type'] as String;
  }

  @override
  String UUID;

  @override
  bool isVisible;

  @override
  String name;

  @override
  String prototypeNodeUUID;

  @override
  PBStyle style;

  @override
  String type;

  @override
  Future<PBIntermediateNode> interpretNode(PBContext currentContext) async {
    var img = await AzureAssetService().downloadImage(UUID);

    var file =
        File('${MainInfo().outputPath}pngs/${UUID}.png'.replaceAll(':', '_'))
          ..createSync(recursive: true);
    file.writeAsBytesSync(img);
    return Future.value(
        InheritedBitmap(this, name, currentContext: currentContext));
  }

  @override
  toJson() {
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toPBDF() {
    throw UnimplementedError();
  }

  @override
  var boundaryRectangle;
}

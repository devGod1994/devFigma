import 'package:parabeac_core/design_logic/rect.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_intermediate_node.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_context.dart';

abstract class DesignNode {
  DesignNode(
    this.UUID,
    this.name,
    this.isVisible,
    this.boundaryRectangle,
    this.type,
    this.style,
  );

  String UUID;
  String name;
  bool isVisible;
  var boundaryRectangle;
  String type;
  var style;

  Future<PBIntermediateNode> interpretNode(PBContext currentContext);

  // DesignNode.fromJson(Map<String, dynamic> json);
  // Map<String, dynamic> toJson();
}

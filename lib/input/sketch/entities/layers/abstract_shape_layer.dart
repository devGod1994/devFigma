// title: Abstract Shape Layer
// description: Abstract base layer for all shape layers
import 'package:parabeac_core/design_logic/design_shape.dart';
import 'package:parabeac_core/input/sketch/entities/layers/abstract_layer.dart';
import 'package:parabeac_core/input/sketch/entities/layers/flow.dart';
import 'package:parabeac_core/input/sketch/entities/objects/frame.dart';
import 'package:parabeac_core/input/sketch/entities/style/style.dart';

abstract class AbstractShapeLayer extends SketchNode implements DesignShape {
  final bool edited;
  final bool isClosed;
  final dynamic pointRadiusBehaviour;
  final List points;

  AbstractShapeLayer(
      this.edited,
      this.isClosed,
      this.pointRadiusBehaviour,
      this.points,
      UUID,
      booleanOperation,
      exportOptions,
      Frame boundaryRectangle,
      Flow flow,
      isFixedToViewport,
      isFlippedHorizontal,
      isFlippedVertical,
      isLocked,
      isVisible,
      layerListExpandedType,
      name,
      nameIsFixed,
      resizingConstraint,
      resizingType,
      rotation,
      sharedStyleID,
      shouldBreakMaskChain,
      hasClippingMask,
      clippingMaskMode,
      userInfo,
      Style style,
      maintainScrollPosition)
      : super(
            UUID,
            booleanOperation,
            exportOptions,
            boundaryRectangle,
            flow,
            isFixedToViewport,
            isFlippedHorizontal,
            isFlippedVertical,
            isLocked,
            isVisible,
            layerListExpandedType,
            name,
            nameIsFixed,
            resizingConstraint,
            resizingType,
            rotation,
            sharedStyleID,
            shouldBreakMaskChain,
            hasClippingMask,
            clippingMaskMode,
            userInfo,
            style,
            maintainScrollPosition);
  @override
  Map<String, dynamic> toJson();
}

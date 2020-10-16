import 'package:parabeac_core/design_logic/pb_shared_instance_design_node.dart';
import 'package:parabeac_core/input/sketch/entities/abstract_sketch_node_factory.dart';
import 'package:parabeac_core/input/sketch/entities/layers/abstract_layer.dart';
import 'package:parabeac_core/input/sketch/entities/layers/flow.dart';
import 'package:parabeac_core/input/sketch/entities/objects/frame.dart';
import 'package:parabeac_core/input/sketch/entities/objects/override_value.dart';
import 'package:parabeac_core/input/sketch/entities/style/style.dart';
import 'package:parabeac_core/input/sketch/helper/symbol_node_mixin.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/pb_shared_instance.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_intermediate_node.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_context.dart';
part 'symbol_instance.g.dart';

// title: Symbol Instance Layer
// description: Symbol instance layers represent an instance of a symbol master
@JsonSerializable(nullable: true)
class SymbolInstance extends SketchNode
    with SymbolNodeMixin
    implements SketchNodeFactory, PBSharedInstanceDesignNode {
  @override
  String CLASS_NAME = 'symbolInstance';
  final List<OverridableValue> overrideValues;
  final double scale;
  @override
  String symbolID;
  final double verticalSpacing;
  final double horizontalSpacing;

  @override
  @JsonKey(name: 'frame')
  var boundaryRectangle;

  @override
  @JsonKey(name: 'do_objectID')
  String UUID;

  @override
  @JsonKey(name: '_class')
  String type;

  bool _isVisible;

  Style _style;

  @override
  void set isVisible(bool _isVisible) => this._isVisible = _isVisible;

  @override
  bool get isVisible => _isVisible;

  @override
  void set style(_style) => this._style = _style;

  @override
  Style get style => _style;

  SymbolInstance(
      {this.UUID,
      booleanOperation,
      exportOptions,
      Frame this.boundaryRectangle,
      Flow flow,
      bool isFixedToViewport,
      bool isFlippedHorizontal,
      bool isFlippedVertical,
      bool isLocked,
      bool isVisible,
      layerListExpandedType,
      String name,
      bool nameIsFixed,
      resizingConstraint,
      resizingType,
      int rotation,
      sharedStyleID,
      bool shouldBreakMaskChain,
      bool hasClippingMask,
      int clippingMaskMode,
      userInfo,
      Style style,
      bool maintainScrollPosition,
      this.overrideValues,
      this.scale,
      this.symbolID,
      this.verticalSpacing,
      this.horizontalSpacing})
      : _isVisible = isVisible,
        _style = style,
        super(
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
  SketchNode createSketchNode(Map<String, dynamic> json) =>
      SymbolInstance.fromJson(json);
  factory SymbolInstance.fromJson(Map<String, dynamic> json) =>
      _$SymbolInstanceFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$SymbolInstanceToJson(this);

  ///Converting the [OverridableValue] into [PBSharedParameterValue] to be processed in intermediate phase.
  List<PBSharedParameterValue> _extractParameters() => overrideValues?.map((e) {
        var properties = extractParameter(e.overrideName);
        return PBSharedParameterValue(properties[0], e.value, properties[1]);
      })?.toList();

  @override
  Future<PBIntermediateNode> interpretNode(PBContext currentContext) {
    var sym = PBSharedInstanceIntermediateNode(this, symbolID,
        sharedParamValues: _extractParameters(),
        currentContext: currentContext);
    return Future.value(sym);
  }

  @override
  List parameters;
}

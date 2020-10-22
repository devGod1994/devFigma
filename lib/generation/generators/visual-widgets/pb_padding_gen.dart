import 'dart:mirrors';

import 'package:parabeac_core/interpret_and_optimize/entities/alignments/padding.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/pb_shared_instance.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/pb_shared_master_node.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_intermediate_node.dart';

import '../pb_flutter_generator.dart';
import '../pb_generator.dart';

class PBPaddingGen extends PBGenerator {
  PBPaddingGen() : super();

  String relativePadding(BUILDER_TYPE type, bool isVertical, double value) {
    var fixedValue = value.toStringAsFixed(2);
    if (type != null)  {
      if (type == BUILDER_TYPE.SYMBOL_MASTER) {
        return 'constraints.max' + (isVertical ? 'Height' : 'Width') + ' * $fixedValue';
      }
      return 'MediaQuery.of(context).size.' + (isVertical ? 'height' : 'width') + ' * $fixedValue';
    }
    return '$fixedValue';
  }

  @override
  String generate(PBIntermediateNode source) {
    if (!(source is Padding)) {
      return '';
    }
    final padding = source as Padding;
    var buffer = StringBuffer();
    buffer.write('Padding(');
    buffer.write('padding: EdgeInsets.only(');

    final paddingPositionsW = ['left', 'right'];
    final paddingPositionsH =['bottom', 'top'];
    var reflectedPadding = reflect(padding);
    for (var position in paddingPositionsW) {
      var value = reflectedPadding.getField(Symbol(position)).reflectee;
      if (value != null) {
        buffer.write(
            '$position: ${relativePadding(source.builder_type ?? BUILDER_TYPE.BODY, false, value)},');
      }
    }

    for (var position in paddingPositionsH) {
      var value = reflectedPadding.getField(Symbol(position)).reflectee;
      if (value != null) {
        buffer.write(
            '$position: ${relativePadding(source.builder_type ?? BUILDER_TYPE.BODY, true, value)},');
      }
    }

    buffer.write('),');

    if (source.child != null) {
      buffer.write(
          'child: ${manager.generate(source.child, type: source.builder_type ?? BUILDER_TYPE.BODY)}');
    }
    buffer.write(')');

    return buffer.toString();
  }
}

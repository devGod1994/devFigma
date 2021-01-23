import 'package:parabeac_core/generation/generators/attribute-helper/pb_attribute_gen_helper.dart';
import 'package:parabeac_core/generation/generators/attribute-helper/pb_color_gen_helper.dart';
import 'package:parabeac_core/generation/generators/attribute-helper/pb_generator_context.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_intermediate_node.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/inherited_container.dart';

class PBBoxDecorationHelper extends PBAttributesHelper {
  PBBoxDecorationHelper() : super();

  @override
  String generate(
      PBIntermediateNode source, GeneratorContext generatorContext) {
    if (source is InheritedContainer) {
      final buffer = StringBuffer();
      buffer.write('decoration: BoxDecoration(');
      var borderInfo = source.auxiliaryData.borderInfo;
      if (source.auxiliaryData.color != null) {
        buffer.write(PBColorGenHelper().generate(source, generatorContext));
      }
      if (borderInfo != null) {
        if (borderInfo['shape'] == 'circle') {
          buffer.write('shape: BoxShape.circle,');
        } else if (borderInfo['borderRadius'] != null) {
          buffer.write(
              'borderRadius: BorderRadius.all(Radius.circular(${borderInfo['borderRadius']})),');
          if ((borderInfo['borderColorHex'] != null) ||
              (borderInfo['borderThickness'] != null)) {
            buffer.write('border: Border.all(');
            if (borderInfo['borderColorHex'] != null) {
              buffer.write('color: Color(${borderInfo['borderColorHex']}),');
            }
            if (borderInfo['borderThickness'] != null) {
              buffer.write('width: ${borderInfo['borderThickness']},');
            }
            buffer.write('),'); // end of Border.all(
          }
        }
      }
      buffer.write('),');

      return buffer.toString();
    }
    return '';
  }
}

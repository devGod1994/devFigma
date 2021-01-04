import 'package:parabeac_core/generation/generators/attribute-helper/pb_generator_context.dart';
import 'package:parabeac_core/generation/generators/pb_generator.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/alignments/flexible.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_intermediate_node.dart';
import 'package:quick_log/quick_log.dart';

class PBFlexibleGenerator extends PBGenerator {
  var log = Logger('Flexible Generator');
  PBFlexibleGenerator() : super();

  @override
  String generate(
      PBIntermediateNode source, GeneratorContext generatorContext) {
    if (source is Flexible) {
      var buffer = StringBuffer();
      buffer.write('Flexible(');
      buffer.write('flex: ${source.flex},');
      try {
        buffer.write(
            'child: ${source.child.generator.generate(source.child, generatorContext)},');
      } catch (e) {
        log.error(e.toString());
      }
      buffer.write(')');
      return buffer.toString();
    }
  }
}

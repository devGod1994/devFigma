import 'package:parabeac_core/generation/generators/attribute-helper/pb_generator_context.dart';
import 'package:parabeac_core/generation/generators/pb_generation_manager.dart';
import 'package:parabeac_core/generation/generators/value_objects/template_strategy/pb_template_strategy.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/pb_shared_master_node.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_intermediate_node.dart';
import 'package:recase/recase.dart';

class BLoCStateTemplateStrategy extends TemplateStrategy {
  bool isFirst = true;
  String abstractClassName;
  BLoCStateTemplateStrategy({this.isFirst, this.abstractClassName});
  @override
  String generateTemplate(PBIntermediateNode node, PBGenerationManager manager,
      GeneratorContext generatorContext,
      {args}) {
    var widgetName = retrieveNodeName(node);
    var returnStatement = node.generator.generate(node, generatorContext);
    var overrides = '';
    var overrideVars = '';
    if (node is PBSharedMasterNode && node.overridableProperties.isNotEmpty) {
      node.overridableProperties.forEach((prop) {
        overrides += 'this.${prop.friendlyName}, ';
        overrideVars += 'final ${prop.friendlyName};';
      });
    }
    return '''
${isFirst ? _getHeader(manager) : ''}

class ${node.name.pascalCase}State extends ${abstractClassName.pascalCase}State{

  @override
  Widget get widget => ${returnStatement};

}''';
  }

  String _getHeader(manager) {
    return '''
    part of '${abstractClassName.snakeCase}_bloc.dart';

    @immutable
    abstract class ${abstractClassName.pascalCase}State{
      Widget get widget;
    }
    ''';
  }
}

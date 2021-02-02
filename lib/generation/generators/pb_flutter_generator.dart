import 'package:parabeac_core/generation/generators/attribute-helper/pb_generator_context.dart';
import 'package:parabeac_core/generation/generators/pb_generation_manager.dart';
import 'package:parabeac_core/generation/generators/util/pb_generation_view_data.dart';
import 'package:parabeac_core/generation/generators/value_objects/template_strategy/empty_page_template_strategy.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_intermediate_node.dart';
import 'package:quick_log/quick_log.dart';

class PBFlutterGenerator extends PBGenerationManager {
  var log = Logger('Flutter Generator');
  final DEFAULT_STRATEGY = EmptyPageTemplateStrategy();
  PBFlutterGenerator({PBGenerationViewData data}) : super(data: data) {
    body = StringBuffer();
  }

  ///Generates a constructor given a name and `constructorVariable`
  @override
  String generateConstructor(name) {
    if (data.constructorVariables == null) {
      return '';
    }
    var stringBuffer = StringBuffer();
    stringBuffer.write(name + '(');
    var param;
    var it = data.constructorVariables;
    while (it.moveNext()) {
      param = it.current;
      if (param.isRequired) {
        stringBuffer.write('this.' + param.variableName + ',');
      }
      param = it.current;
    }

    var counter = 0;
    var optionalParamBuffer = StringBuffer();
    optionalParamBuffer.write('{');
    it = data.constructorVariables;
    while (it.moveNext()) {
      param = data.constructorVariables.current;
      if (!param.isRequired) {
        optionalParamBuffer.write('this.' + param.variableName + ',');
        counter++;
      }
    }
    optionalParamBuffer.write('}');
    if (counter >= 1) {
      stringBuffer.write(optionalParamBuffer.toString());
    }
    stringBuffer.write(');');
    return stringBuffer.toString();
  }

  ///Generate global variables
  @override
  String generateGlobalVariables() {
    if (data.globalVariables == null) {
      return '';
    }
    var stringBuffer = StringBuffer();
    var param;
    var it = data.globalVariables;
    while (it.moveNext()) {
      param = it.current;
      stringBuffer.write(param.type +
          ' ' +
          param.variableName +
          (param.defaultValue == null ? '' : ' = ${param.defaultValue}') +
          ';\n');
    }
    return stringBuffer.toString();
  }

  /// Generates the imports
  @override
  String generateImports() {
    var buffer = StringBuffer();
    buffer.write('import \'package:flutter/material.dart\';\n');
    var it = data.imports;
    while (it.moveNext()) {
      buffer.write('import \'${it.current}\';\n');
    }
    return buffer.toString();
  }

  /// Generates the dispose method
  String generateDispose() {
    var buffer = StringBuffer();
    var it = data.toDispose;
    while (it.moveNext()) {
      buffer.write('${it.current};\n');
    }
    return '''
    @override
    void dispose() {
      ${buffer.toString()}
      super.dispose();
    }
    ''';
  }

  @override
  String generate(
    PBIntermediateNode rootNode,
  ) {
    if (rootNode == null) {
      return null;
    }
    rootNode.generator.manager = this;
    if (rootNode.generator == null) {
      log.error('Generator not registered for ${rootNode}');
    }
    return rootNode.generator?.templateStrategy?.generateTemplate(
            rootNode,
            this,
            GeneratorContext(sizingContext: SizingValueContext.PointValue)) ??

        ///if there is no [TemplateStrategy] we are going to use `DEFAULT_STRATEGY`
        DEFAULT_STRATEGY.generateTemplate(rootNode, this,
            GeneratorContext(sizingContext: SizingValueContext.PointValue));
  }
}

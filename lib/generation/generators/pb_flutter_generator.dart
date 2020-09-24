import 'package:parabeac_core/generation/generators/pb_param.dart';
import 'package:parabeac_core/generation/generators/pb_widget_manager.dart';
import 'package:parabeac_core/generation/generators/util/pb_input_formatter.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/pb_shared_instance.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/pb_shared_master_node.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_intermediate_node.dart';
import 'package:quick_log/quick_log.dart';

enum BUILDER_TYPE {
  STATEFUL_WIDGET,
  SYMBOL_MASTER,
  SYMBOL_INSTANCE,
  STATELESS_WIDGET,
  BODY,
  SCAFFOLD_BODY,
  EMPTY_PAGE
}

class PBFlutterGenerator extends PBGenerationManager {
  var log = Logger('Flutter Generator');
  PBFlutterGenerator(pageWriter) : super(pageWriter) {
    body = StringBuffer();
  }

  String generateStatefulWidget(String body, String name) {
    var widgetName = _generateWidgetName(name);
    var constructorName = '_$name';
    return '''
${generateImports()}

class ${widgetName} extends StatefulWidget{
  const ${widgetName}() : super();
  @override
  _${widgetName} createState() => _${widgetName}();
}

class _${widgetName} extends State<${widgetName}>{
  ${generateInstanceVariables()}
  ${generateConstructor(constructorName)}

  @override
  Widget build(BuildContext context){
    return ${body};
  }
}''';
  }

  String generateStatelessWidget(String body, String name) {
    var widgetName = _generateWidgetName(name);
    var constructorName = '_$name';
    return '''
${generateImports()}

class ${widgetName} extends StatelessWidget{
  const ${widgetName}({Key key}) : super(key : key);
  ${generateInstanceVariables()}
  ${generateConstructor(constructorName)}

  @override
  Widget build(BuildContext context){
    return ${body};
  }
}''';
  }

  String _generateWidgetName(name) => PBInputFormatter.formatLabel(
        name,
        isTitle: true,
        space_to_underscore: false,
      );

  String generateConstructor(name) {
    if (constructorVariables == null || constructorVariables.isEmpty) {
      return '';
    }
    List<PBParam> variables = [];
    List<PBParam> optionalVariables = [];
    constructorVariables.forEach((param) {
      // Only accept constructor variable if they are
      // part of the variable instances
      if (param.isRequired && instanceVariables.contains(param)) {
        variables.add(param);
      } else if (instanceVariables.contains(param)) {
        optionalVariables.add(param);
      } else {} // Do nothing
    });
    var stringBuffer = StringBuffer();
    stringBuffer.write(name + '(');
    variables.forEach((p) {
      stringBuffer.write('this.' + p.variableName + ',');
    });
    stringBuffer.write('{');
    optionalVariables.forEach((o) {
      stringBuffer.write('this.' + o.variableName + ',');
    });
    stringBuffer.write('});');
    return stringBuffer.toString();
  }

  String generateInstanceVariables() {
    if (instanceVariables == null || instanceVariables.isEmpty) {
      return '';
    }
    var stringBuffer = StringBuffer();
    instanceVariables.forEach((param) {
      stringBuffer.write(param.type + ' ' + param.variableName + ';\n');
    });

    return stringBuffer.toString();
  }

  /// Formats and returns imports in the list
  String generateImports() {
    StringBuffer buffer = StringBuffer();
    buffer.write('import \'package:flutter/material.dart\';\n');

    for (String import in imports) {
      buffer.write('import \'$import\';\n');
    }
    return buffer.toString();
  }

  @override
  String generate(PBIntermediateNode rootNode,
      {type = BUILDER_TYPE.STATEFUL_WIDGET}) {
    if (rootNode == null) {
      return null;
    }

    ///Automatically assign type for symbols
    if (rootNode is PBSharedMasterNode) {
      type = BUILDER_TYPE.SYMBOL_MASTER;
    } else if (rootNode is PBSharedInstanceIntermediateNode) {
      type = BUILDER_TYPE.SYMBOL_INSTANCE;
    }
    rootNode.builder_type = type;

    rootNode.generator.manager = this;

    var gen = rootNode.generator;

    if (gen != null) {
      switch (type) {
        case BUILDER_TYPE.STATEFUL_WIDGET:
          return generateStatefulWidget(gen.generate(rootNode), rootNode.name);
          break;
        case BUILDER_TYPE.STATELESS_WIDGET:
          return generateStatelessWidget(
              gen.generate(rootNode), rootNode.name);
          break;
        case BUILDER_TYPE.EMPTY_PAGE:
          return generateImports() + body.toString();
          break;
        case BUILDER_TYPE.SYMBOL_MASTER:
        case BUILDER_TYPE.SYMBOL_INSTANCE:
        case BUILDER_TYPE.BODY:
        default:
          return gen.generate(rootNode);
      }
    } else {
      log.error('Generator not registered for ${rootNode}');
    }
    return null;
  }

  @override
  void addDependencies(String packageName, String version) {
    pageWriter.addDependency(packageName, version);
  }

  @override
  void addInstanceVariable(PBParam param) => instanceVariables.add(param);

  @override
  void addConstructorVariable(PBParam param) => constructorVariables.add(param);

  @override
  void addImport(String value) => imports.add(value);
}

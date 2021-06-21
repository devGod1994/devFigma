import 'package:parabeac_core/generation/flutter_project_builder/import_helper.dart';
import 'package:parabeac_core/generation/generators/middleware/middleware.dart';
import 'package:parabeac_core/generation/generators/middleware/state_management/utils/middleware_utils.dart';
import 'package:parabeac_core/generation/generators/pb_generation_manager.dart';
import 'package:parabeac_core/generation/generators/util/pb_generation_view_data.dart';
import 'package:parabeac_core/generation/generators/value_objects/file_structure_strategy.dart/provider_file_structure_strategy.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/pb_shared_instance.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_gen_cache.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_symbol_storage.dart';
import 'package:recase/recase.dart';
import 'package:parabeac_core/generation/generators/value_objects/generator_adapter.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_intermediate_node.dart';

import '../../pb_flutter_generator.dart';

class ProviderMiddleware extends Middleware {
  final PACKAGE_NAME = 'provider';
  final PACKAGE_VERSION = '^4.3.2+3';

  ProviderMiddleware(PBGenerationManager generationManager)
      : super(generationManager);

  @override
  Future<PBIntermediateNode> applyMiddleware(PBIntermediateNode node) async {
    String watcherName;
    var managerData = node.managerData;
    var fileStrategy = node.currentContext.project.fileStructureStrategy
        as ProviderFileStructureStrategy;
    if (node is PBSharedInstanceIntermediateNode) {
      node.currentContext.project.genProjectData
          .addDependencies(PACKAGE_NAME, PACKAGE_VERSION);
      managerData.addImport('package:provider/provider.dart');
      watcherName = getVariableName(node.name.snakeCase + '_notifier');

      addImportToCache(node.SYMBOL_ID, getImportPath(node, fileStrategy));
      PBGenCache().appendToCache(node.SYMBOL_ID,
          getImportPath(node, fileStrategy, generateModelPath: false));

      if (node.generator is! StringGeneratorAdapter) {
        var modelName = ImportHelper.getName(node.functionCallName).pascalCase;
        var providerWidget = '''
        ChangeNotifierProvider(
          create: (context) =>
              ${modelName}('${node.name}'), 
          child: LayoutBuilder(
            builder: (context, constraints) {
              var layout = ${MiddlewareUtils.generateVariableBody(node)};
              
              context
                  .read<${modelName}>()
                  .setCurrentLayout(
                      layout); // Setting active state

              return GestureDetector(
                onTap: () => context.read<
                    ${modelName}>().onGesture(),
                child: Consumer<$modelName>(
                  builder: (context, ${modelName.toLowerCase()}, child) => ${modelName.toLowerCase()}.currentLayout
                ),
              );
            },
          ),
        )
        ''';
        node.generator = StringGeneratorAdapter(providerWidget);
      }
      return node;
    }
    watcherName = getNameOfNode(node);

    var parentDirectory = ImportHelper.getName(node.name).snakeCase;

    // Generate model's imports
    var modelGenerator = PBFlutterGenerator(
        data: PBGenerationViewData()
          ..addImport('package:flutter/material.dart'));
    // Write model class for current node
    var code = MiddlewareUtils.generateModelChangeNotifier(
        watcherName, modelGenerator, node);
    fileStrategy.writeProviderModelFile(code, parentDirectory);

    // Generate default node's view page
    await fileStrategy.generatePage(
      await generationManager.generate(node),
      '${parentDirectory}/${node.name.snakeCase}',
      args: 'VIEW',
    );

    // Generate node's states' view pages
    node.auxiliaryData?.stateGraph?.states?.forEach((state) async {
      await fileStrategy.generatePage(
        await generationManager.generate(state.variation.node),
        '${parentDirectory}/${state.variation.node.name.snakeCase}',
        args: 'VIEW',
      );
    });

    return node;
  }

  String getImportPath(PBSharedInstanceIntermediateNode node,
      ProviderFileStructureStrategy fileStrategy,
      {bool generateModelPath = true}) {
    var symbolMaster =
        PBSymbolStorage().getSharedMasterNodeBySymbolID(node.SYMBOL_ID);
    var import = generateModelPath
        ? '${fileStrategy.RELATIVE_MODEL_PATH}${ImportHelper.getName(symbolMaster.name).snakeCase}.dart'
        : '${fileStrategy.RELATIVE_VIEW_PATH}${ImportHelper.getName(symbolMaster.name).snakeCase}/${node.functionCallName.snakeCase}.dart';
    return fileStrategy.GENERATED_PROJECT_PATH + import;
  }
}

import 'package:parabeac_core/generation/flutter_project_builder/import_helper.dart';
import 'package:parabeac_core/generation/generators/middleware/middleware.dart';
import 'package:parabeac_core/generation/generators/util/pb_generation_view_data.dart';
import 'package:parabeac_core/generation/generators/writers/pb_flutter_writer.dart';
import 'package:parabeac_core/generation/generators/pb_generation_manager.dart';
import 'package:parabeac_core/generation/generators/pb_generator.dart';
import 'package:parabeac_core/generation/generators/writers/pb_page_writer.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/inherited_scaffold.dart';
import 'package:parabeac_core/generation/generators/value_objects/file_structure_strategy.dart/flutter_file_structure_strategy.dart';
import 'package:parabeac_core/generation/generators/value_objects/file_structure_strategy.dart/pb_file_structure_strategy.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/pb_shared_instance.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_intermediate_node.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_layout_intermediate_node.dart';
import 'package:parabeac_core/generation/generators/pb_flutter_generator.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_symbol_storage.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_project.dart';
import 'package:quick_log/quick_log.dart';
import 'package:recase/recase.dart';

abstract class GenerationConfiguration {
  FileStructureStrategy fileStructureStrategy;

  Logger logger;

  final Set<Middleware> _middleware = {};

  ///The project that contains the node for all the pages.
  PBProject pbProject;

  ///The manager in charge of the independent [PBGenerator]s by providing an interface for adding imports, global variables, etc.
  ///
  ///The default [PBGenerationManager] will be [PBFlutterGenerator]
  PBGenerationManager _generationManager;

  /// PageWriter to be used for generation
  PBPageWriter _pageWriter = PBFlutterWriter(); // Default to Flutter
  PBPageWriter get pageWriter => _pageWriter;

  set pageWriter(PBPageWriter pageWriter) => _pageWriter = pageWriter;

  GenerationConfiguration() {
    logger = Logger(runtimeType.toString());
    _generationManager = PBFlutterGenerator(data: PBGenerationViewData());
  }

  PBGenerationManager get generationManager => _generationManager;
  set generationManager(PBGenerationManager manager) =>
      _generationManager = manager;

  final Map<String, String> _dependencies = {};
  Iterable<MapEntry<String, String>> get dependencies => _dependencies.entries;

  ///This is going to modify the [PBIntermediateNode] in order to affect the structural patterns or file structure produced.
  Future<PBIntermediateNode> applyMiddleware(PBIntermediateNode node) async {
    var it = _middleware.iterator;
    while (it.moveNext()) {
      node = await it.current.applyMiddleware(node);
    }
    return node;
  }

  Future<PBIntermediateNode> conditionsToApplyMiddleware(
      PBIntermediateNode node) async {
    if ((node is PBSharedInstanceIntermediateNode && _isMasterState(node)) ||
        (node?.auxiliaryData?.stateGraph?.states?.isNotEmpty ?? false)) {
      return await applyMiddleware(node);
    }
    return node;
  }

  bool _isMasterState(PBSharedInstanceIntermediateNode node) {
    if (node.isMasterState) {
      return true;
    }
    var symbolMaster =
        PBSymbolStorage().getSharedMasterNodeBySymbolID(node.SYMBOL_ID);
    return symbolMaster?.auxiliaryData?.stateGraph?.states?.isNotEmpty ?? false;
  }

  Future<PBIntermediateNode> _iterateNode(PBIntermediateNode node) async {
    var stack = <PBIntermediateNode>[node];
    while (stack.isNotEmpty) {
      var currentNode = stack.removeLast();

      /// Add all children to the stack
      if (currentNode.child != null) {
        stack.add(currentNode.child);
      } else if (currentNode is PBLayoutIntermediateNode) {
        currentNode.children.forEach((node) {
          stack.add(node);
        });
      }

      /// Apply incoming function to all nodes
      await conditionsToApplyMiddleware(currentNode);
    }
    return node;
  }

  ///generates the Project based on the [pb_project]
  Future<void> generateProject(PBProject pb_project) async {
    pbProject = pb_project;

    await setUpConfiguration();
    pbProject.fileStructureStrategy = fileStructureStrategy;
    for (var tree in pbProject.forest) {
      _generationManager.data = tree.data;
      var fileName = tree.rootNode?.name?.snakeCase ?? 'no_name_found';
      if (tree.rootNode is InheritedScaffold &&
          (tree.rootNode as InheritedScaffold).isHomeScreen) {
        _setMainScreen(
            tree.rootNode, '${tree.name.snakeCase}/${fileName}.dart');
      }
      _commitImports(tree.rootNode, tree.name.snakeCase, fileName);
      await _iterateNode(tree.rootNode);

      await _generateNode(tree.rootNode, '${tree.name.snakeCase}/${fileName}');
    }
    await _commitDependencies(pb_project.projectName);
  }

  void registerMiddleware(Middleware middleware) {
    if (middleware != null) {
      middleware.generationManager = _generationManager;
      _middleware.add(middleware);
    }
  }

  Future<void> setUpConfiguration() async {
    fileStructureStrategy = FlutterFileStructureStrategy(
        pbProject.projectAbsPath, _pageWriter, pbProject);
    logger.info('Setting up the directories');
    await fileStructureStrategy.setUpDirectories();
  }

  void _commitImports(
      PBIntermediateNode node, String directoryName, String fileName) {
    var screenFilePath =
        '${pbProject.projectName}/lib/screens/${directoryName}/${fileName.snakeCase}.dart';
    var viewFilePath =
        '${pbProject.projectName}/lib/views/${directoryName}/${fileName.snakeCase}.dart'; // Removed .g
    var imports = ImportHelper.findImports(
        node, node is InheritedScaffold ? screenFilePath : viewFilePath);
    imports.forEach((import) {
      node.managerData.addImport(import);
    });
  }

  Future<void> _commitDependencies(String projectName) async {
    var writer = _pageWriter;
    if (writer is PBFlutterWriter) {
      writer.submitDependencies(projectName + '/pubspec.yaml');
    }
  }

  void _setMainScreen(InheritedScaffold node, String outputMain) {
    var writer = _pageWriter;
    if (writer is PBFlutterWriter) {
      writer.writeMainScreenWithHome(
          node.name,
          fileStructureStrategy.GENERATED_PROJECT_PATH + 'lib/main.dart',
          'screens/${outputMain}');
    }
  }

  Future<void> _generateNode(PBIntermediateNode node, String filename) async {
    if (node?.auxiliaryData?.stateGraph?.states?.isNotEmpty ?? false) {
      /// Since these nodes are being processed on the middlewares
      /// we can ignore them here
      /// TODO: change it
    } else {
      await pbProject.fileStructureStrategy.generatePage(
          await _generationManager.generate(node), filename,
          args: node is InheritedScaffold ? 'SCREEN' : 'VIEW');
    }
  }
}

import 'package:parabeac_core/generation/flutter_project_builder/import_helper.dart';
import 'package:parabeac_core/generation/generators/import_generator.dart';
import 'package:parabeac_core/generation/generators/middleware/middleware.dart';
import 'package:parabeac_core/generation/generators/util/pb_generation_view_data.dart';
import 'package:parabeac_core/generation/generators/value_objects/file_structure_strategy/command_invoker.dart';
import 'package:parabeac_core/generation/generators/value_objects/file_structure_strategy/commands/export_platform_command.dart';
import 'package:parabeac_core/generation/generators/value_objects/file_structure_strategy/commands/file_structure_command.dart';
import 'package:parabeac_core/generation/generators/value_objects/file_structure_strategy/commands/orientation_builder_command.dart';
import 'package:parabeac_core/generation/generators/value_objects/file_structure_strategy/commands/responsive_layout_builder_command.dart';
import 'package:parabeac_core/generation/generators/value_objects/file_structure_strategy/commands/write_screen_command.dart';
import 'package:parabeac_core/generation/generators/value_objects/file_structure_strategy/commands/write_symbol_command.dart';
import 'package:parabeac_core/generation/generators/value_objects/file_structure_strategy/file_structure_strategy_collector.dart';
import 'package:parabeac_core/generation/generators/value_objects/generation_configuration/pb_platform_orientation_generation_mixin.dart';
import 'package:parabeac_core/generation/generators/writers/pb_flutter_writer.dart';
import 'package:parabeac_core/generation/generators/pb_generation_manager.dart';
import 'package:parabeac_core/generation/generators/pb_generator.dart';
import 'package:parabeac_core/generation/generators/writers/pb_page_writer.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/inherited_scaffold.dart';
import 'package:parabeac_core/generation/generators/value_objects/file_structure_strategy/flutter_file_structure_strategy.dart';
import 'package:parabeac_core/generation/generators/value_objects/file_structure_strategy/pb_file_structure_strategy.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/pb_shared_instance.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_intermediate_node.dart';
import 'package:parabeac_core/generation/generators/pb_flutter_generator.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_gen_cache.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_intermediate_node_tree.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_symbol_storage.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_project.dart';
import 'package:parabeac_core/interpret_and_optimize/services/pb_platform_orientation_linker_service.dart';
import 'package:quick_log/quick_log.dart';
import 'package:recase/recase.dart';
import 'package:path/path.dart' as p;

abstract class GenerationConfiguration with PBPlatformOrientationGeneration {
  FileStructureStrategy fileStructureStrategy;

  Logger logger;

  final Set<Middleware> _middleware = {};
  Set<Middleware> get middlewares => _middleware;

  ///The manager in charge of the independent [PBGenerator]s by providing an interface for adding imports, global variables, etc.
  ///
  ///The default [PBGenerationManager] will be [PBFlutterGenerator]
  PBGenerationManager generationManager;

  PBPlatformOrientationLinkerService poLinker;

  ImportHelper _importProcessor;

  @Deprecated('Use [FileStructureCommands instead of using the pageWriter.]')

  /// PageWriter to be used for generation
  PBPageWriter pageWriter = PBFlutterWriter(); // Default to Flutter

  final Map<String, String> _dependencies = {};
  Iterable<MapEntry<String, String>> get dependencies => _dependencies.entries;

  /// List of observers that will be notified when a new command is added.
  final commandObservers = <CommandInvoker>[];

  GenerationConfiguration() {
    logger = Logger(runtimeType.toString());
    _importProcessor ??= ImportHelper();
    generationManager ??=
        PBFlutterGenerator(_importProcessor, data: PBGenerationViewData());
    poLinker ??= PBPlatformOrientationLinkerService();
  }

  ///This is going to modify the [PBIntermediateNode] in order to affect the structural patterns or file structure produced.
  Future<PBIntermediateNode> applyMiddleware(PBIntermediateNode node) async {
    var it = _middleware.iterator;
    while (it.moveNext()) {
      node = await it.current.applyMiddleware(node);
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

  ///Applying the registered [Middleware] to all the [PBIntermediateNode]s within the [PBIntermediateTree]
  Future<PBIntermediateTree> _applyMiddleware(PBIntermediateTree tree) async {
    for (var node in tree) {
      if ((node is PBSharedInstanceIntermediateNode && _isMasterState(node)) ||
          (node?.auxiliaryData?.stateGraph?.states?.isNotEmpty ?? false)) {
        await applyMiddleware(node);
      }
    }
    return tree;
  }

  Future<void> generateTrees(
      List<PBIntermediateTree> trees, PBProject project) async {
    for (var tree in trees) {
      // var tree = trees.current;
      tree.rootNode.currentContext.generationManager = generationManager;

      tree.data.addImport(FlutterImport('material.dart', 'flutter'));
      generationManager.data = tree.data;
      var fileName = tree.identifier?.snakeCase ?? 'no_name_found';

      // Relative path to the file to create
      var relPath =
          p.setExtension(p.join(tree.name.snakeCase, fileName), '.dart');

      // Change relative path if current tree is part of multi-platform setup
      if (poLinker.screenHasMultiplePlatforms(tree.identifier)) {
        var platformFolder =
            poLinker.stripPlatform(tree.rootNode.managerData.platform);
        relPath = p.join(fileName, platformFolder, fileName);
      }
      if (tree.rootNode is InheritedScaffold &&
          (tree.rootNode as InheritedScaffold).isHomeScreen) {
        await _setMainScreen(tree, relPath);
      }
      await _applyMiddleware(tree);

      fileStructureStrategy
          .commandCreated(_createCommand(fileName, tree, project));
    }
  }

  ///Generates the [PBIntermediateTree]s within the [pb_project]
  Future<void> generateProject(PBProject pb_project) async {
    ///First we are going to perform a dry run in the generation to
    ///gather all the necessary information
    configDryRun(pb_project);
    pb_project.fileStructureStrategy = fileStructureStrategy;
    await generateTrees(pb_project.forest, pb_project);
    // var dryRunCommands =
    //     (fileStructureStrategy as DryRunFileStructureStrategy).dryRunCommands;

    ///After the dry run is complete, then we are able to create the actual files.
    await setUpConfiguration(pb_project);
    pb_project.fileStructureStrategy = fileStructureStrategy;
    // dryRunCommands.forEach(fileStructureStrategy.commandCreated);
    await generateTrees(pb_project.forest, pb_project);

    await _commitDependencies(pb_project.projectAbsPath);
  }

  FileStructureCommand _createCommand(
      String fileName, PBIntermediateTree tree, PBProject project) {
    var command;
    if (poLinker.screenHasMultiplePlatforms(tree.identifier)) {
      getPlatformOrientationName(tree.rootNode);
      if (_importProcessor.imports.isNotEmpty) {
        var treePath = p.join(project.projectAbsPath,
            ExportPlatformCommand.WIDGET_PATH, fileName);
        _traverseTreeForImports(
            tree, p.setExtension(treePath, '.dart'), project.projectName);
      }
      command = ExportPlatformCommand(
        tree.UUID,
        tree.rootNode.currentContext.tree.data.platform,
        fileName,
        p.setExtension(tree.rootNode.name.snakeCase, '.dart'),
        generationManager.generate(tree.rootNode),
      );
    } else if (tree.rootNode is InheritedScaffold) {
      if (_importProcessor.imports.isNotEmpty) {
        var treePath = p.join(
            project.projectAbsPath, WriteScreenCommand.SCREEN_PATH, fileName);
        _traverseTreeForImports(
            tree, p.setExtension(treePath, '.dart'), project.projectName);
      }
      command = WriteScreenCommand(
        tree.UUID,
        p.setExtension(fileName, '.dart'),
        tree.name.snakeCase,
        generationManager.generate(tree.rootNode),
      );
    } else {
      var relativePath = '${tree.name.snakeCase}/';
      if (_importProcessor.imports.isNotEmpty) {
        var treePath = p.join(project.projectAbsPath,
            WriteSymbolCommand.SYMBOL_PATH, relativePath, fileName);
        _traverseTreeForImports(
            tree, p.setExtension(treePath, '.dart'), project.projectName);
      }
      command = WriteSymbolCommand(
        tree.UUID,
        p.setExtension(fileName, '.dart'),
        generationManager.generate(tree.rootNode),
        relativePath: relativePath,
      );
    }
    return command;
  }

  /// Method that traverses `tree`'s dependencies and looks for an import path from
  /// [ImportHelper].
  ///
  /// If an import path is found, it will be added to the `tree`'s data. The package format
  /// for imports is going to be enforced, therefore, [packageName] is going to be
  /// a required parameter.
  void _traverseTreeForImports(
      PBIntermediateTree tree, String treeAbsPath, String packageName) {
    var iter = tree.dependentOn;
    var addImport = tree.rootNode.managerData.addImport;

    if (iter.moveNext()) {
      var dependency = iter.current;
      var import = _importProcessor.getImport(dependency.UUID);
      if (import != null) {
        addImport(FlutterImport(import, packageName));
      }
    }
  }

  void registerMiddleware(Middleware middleware) {
    if (middleware != null) {
      middleware.generationManager = generationManager;
      _middleware.add(middleware);
    }
  }

  /// going to run the [generateProject] without actually creating or modifying any file
  ///
  /// The main purpose of this is to collect all the information necessary to run a successful
  /// generation. For example, if we ran it normally, there would be imports missing because we could
  /// not determine the final position of some dependencies.
  FileStructureStrategy configDryRun(PBProject pbProject) {
    fileStructureStrategy = DryRunFileStructureStrategy(
        pbProject.projectAbsPath, pageWriter, pbProject);
    fileStructureStrategy.addFileObserver(_importProcessor);

    ///TODO: Once [GenerationConfiguraion] is init from the beginning in PBC, we can remove the need of a queue
    pbProject.genProjectData.commandQueue
        .forEach(fileStructureStrategy.commandCreated);

    logger.info('Running Generation Dry Run...');
    return fileStructureStrategy;
  }

  ///Configure the required classes for the [PBGenerationConfiguration]
  Future<void> setUpConfiguration(PBProject pbProject) async {
    fileStructureStrategy = FlutterFileStructureStrategy(
        pbProject.projectAbsPath, pageWriter, pbProject);
    commandObservers.add(fileStructureStrategy);
    fileStructureStrategy.addFileObserver(_importProcessor);

    // Execute command queue
    var queue = pbProject.genProjectData.commandQueue;
    while (queue.isNotEmpty) {
      var command = queue.removeLast();
      commandObservers.forEach((observer) => observer.commandCreated(command));
    }
    logger.info('Setting up the directories');
    await fileStructureStrategy.setUpDirectories();
  }

  Future<void> _commitDependencies(String projectPath) async {
    var writer = pageWriter;
    if (writer is PBFlutterWriter) {
      writer.submitDependencies(p.join(projectPath, 'pubspec.yaml'));
    }
  }

  Future<void> _setMainScreen(
      PBIntermediateTree tree, String outputMain) async {
    var writer = pageWriter;
    var nodeInfo = _determineNode(tree, outputMain);
    if (writer is PBFlutterWriter) {
      await writer.writeMainScreenWithHome(
          nodeInfo[0],
          p.join(fileStructureStrategy.GENERATED_PROJECT_PATH, 'lib/main.dart'),
          'screens/${nodeInfo[1]}');
    }
  }

  List<String> _determineNode(PBIntermediateTree tree, String outputMain) {
    var rootName = tree.rootNode.name;
    if (rootName.contains('_')) {
      rootName = rootName.split('_')[0].pascalCase;
    }
    var currentMap = PBPlatformOrientationLinkerService()
        .getPlatformOrientationData(rootName);
    var className = [rootName.pascalCase, ''];
    if (currentMap.length > 1) {
      className[0] += 'PlatformBuilder';
      className[1] =
          rootName.snakeCase + '/${rootName.snakeCase}_platform_builder.dart';
    }
    return className;
  }

  Future<void> generatePlatformAndOrientationInstance(PBProject mainTree) {
    var currentMap =
        PBPlatformOrientationLinkerService().getWhoNeedsAbstractInstance();

    currentMap.forEach((screenName, platformsMap) {
      var rawImports = getPlatformImports(screenName);

      rawImports.add(p.join(
        mainTree.fileStructureStrategy.GENERATED_PROJECT_PATH,
        OrientationBuilderCommand.DIR_TO_ORIENTATION_BUILDER,
        OrientationBuilderCommand.NAME_TO_ORIENTAION_BUILDER,
      ));
      rawImports.add(p.join(
        mainTree.fileStructureStrategy.GENERATED_PROJECT_PATH,
        ResponsiveLayoutBuilderCommand.DIR_TO_RESPONSIVE_LAYOUT,
        ResponsiveLayoutBuilderCommand.NAME_TO_RESPONSIVE_LAYOUT,
      ));

      var newCommand = generatePlatformInstance(
          platformsMap, screenName, mainTree, rawImports);

      if (newCommand != null) {
        commandObservers
            .forEach((observer) => observer.commandCreated(newCommand));
      }
    });
  }

  Set<String> getPlatformImports(String screenName) {
    var platformOrientationMap = PBPlatformOrientationLinkerService()
        .getPlatformOrientationData(screenName);
    var imports = <String>{};
    platformOrientationMap.forEach((key, map) {
      map.forEach((key, tree) {
        imports.add(_importProcessor.getImport(tree.UUID));
      });
    });
    // TODO: add import to responsive layout builder

    return imports;
  }
}

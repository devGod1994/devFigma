import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:recase/recase.dart';
import 'package:parabeac_core/controllers/main_info.dart';
import 'package:parabeac_core/eggs/injected_app_bar.dart';
import 'package:parabeac_core/eggs/injected_tab_bar.dart';
import 'package:parabeac_core/generation/generators/pb_flutter_generator.dart';
import 'package:parabeac_core/generation/generators/pb_flutter_writer.dart';
import 'package:parabeac_core/generation/prototyping/pb_dest_holder.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/inherited_scaffold.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/pb_shared_instance.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/pb_shared_master_node.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_intermediate_node.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_layout_intermediate_node.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_gen_cache.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_intermediate_node_tree.dart';
import 'package:quick_log/quick_log.dart';

String pathToFlutterProject = '${MainInfo().outputPath}/temp/';

class FlutterProjectBuilder {
  String projectName;
  String pathToIntermiateFile;
  PBIntermediateTree mainTree;

  var log = Logger('Project Builder');

  ///For right now we are placing all [PBSharedMasterNode]s in a single page
  final bool _symbolsSinglePage = true;

  final String SYMBOL_DIR_NAME = 'symbols';

  FlutterProjectBuilder(
      {this.projectName, this.pathToIntermiateFile, this.mainTree}) {
    pathToFlutterProject = '${projectName}/';
    if (pathToIntermiateFile == null) {
      log.info(
          'Flutter Project Builder must have a JSON file in intermediate format passed to `pathToIntermediateFile`');
      return;
    }
  }

  void convertToFlutterProject({List<ArchiveFile> rawImages}) async {
    try {
      log.info(Process.runSync('flutter', ['create', '$projectName'],
              workingDirectory: MainInfo().outputPath)
          .stdout);
    } catch (error, stackTrace) {
      await MainInfo().sentry.captureException(
            exception: error,
            stackTrace: stackTrace,
          );
      log.error(error.toString());
    }
    // Add Pubspec Assets Lines.
    var list = File('${pathToFlutterProject}pubspec.yaml').readAsLinesSync();
    list.replaceRange(42, 44, ['  assets:', '    - assets/images/']);
    var sink = File('${pathToFlutterProject}pubspec.yaml')
        .openWrite(mode: FileMode.write, encoding: utf8);
    for (var i = 0; i < list.length; i++) {
      sink.writeln(list[i]);
    }
    await sink.close();

    await Directory('${pathToFlutterProject}assets/images')
        .create(recursive: true)
        .then((value) => {
              // print(value),
            })
        .catchError((e) {
      // print(e);
      log.error(e.toString());
    });

    Process.runSync(
        '${MainInfo().cwd.path}/lib/generation/helperScripts/shell-proxy.sh',
        [
          'mv ${MainInfo().outputPath}/pngs/* ${pathToFlutterProject}assets/images/'
        ],
        runInShell: true,
        environment: Platform.environment,
        workingDirectory: '${pathToFlutterProject}assets/');

    // Add all images
    if (rawImages != null) {
      for (var image in rawImages) {
        if (image.name != null) {
          var f = File(
              '${pathToFlutterProject}assets/images/${image.name.replaceAll(" ", "")}.png');
          f.writeAsBytesSync(image.content);
        }
      }
    }

    ///First traversal here (Add imports)
    await _traverseTree(true);

    ///Second traversal here (Find imports)
    await _traverseTree(false);

    var l = File('${pathToFlutterProject}lib/main.dart').readAsLinesSync();
    var s = File('${pathToFlutterProject}lib/main.dart')
        .openWrite(mode: FileMode.write, encoding: utf8);
    for (var i = 0; i < l.length; i++) {
      s.writeln(l[i]);
    }
    await s.close();

    Process.runSync(
        '${MainInfo().cwd.path}/lib/generation/helperScripts/shell-proxy.sh',
        ['rm -rf .dart_tool/build'],
        runInShell: true,
        environment: Platform.environment,
        workingDirectory: '${MainInfo().outputPath}');

    // Remove pngs folder
    Process.runSync(
        '${MainInfo().cwd.path}/lib/generation/helperScripts/shell-proxy.sh',
        ['rm -rf ${MainInfo().outputPath}/pngs'],
        runInShell: true,
        environment: Platform.environment,
        workingDirectory: '${MainInfo().outputPath}');

    log.info(
      Process.runSync(
              'dartfmt',
              [
                '-w',
                '${pathToFlutterProject}bin',
                '${pathToFlutterProject}lib',
                '${pathToFlutterProject}test'
              ],
              workingDirectory: MainInfo().outputPath)
          .stdout,
    );
  }

  /// Traverse the [node] tree, check if any nodes need importing,
  /// and add the relative import from [path] to the [node]
  List<String> _findImports(PBIntermediateNode node, String path) {
    List<String> imports = [];
    if (node == null) return imports;

    String id;
    if (node is PBSharedInstanceIntermediateNode) {
      id = node.SYMBOL_ID;
    } else if (node is PBDestHolder) {
      id = node.pNode.destinationUUID;
    } else {
      id = node.UUID;
    }

    String nodePath = PBGenCache().getPath(id);
    // Make sure nodePath exists and is not the same as path (importing yourself)
    if (nodePath != null && nodePath.isNotEmpty && path != nodePath) {
      imports.add(PBGenCache().getRelativePath(path, id));
    }

    // Recurse through child/children and add to imports
    if (node is PBLayoutIntermediateNode) {
      node.children
          .forEach((child) => imports.addAll(_findImports(child, path)));
    } else if (node is InheritedScaffold) {
      imports.addAll(_findImports(node.navbar, path));
      imports.addAll(_findImports(node.tabbar, path));
      imports.addAll(_findImports(node.child, path));
    } else if (node is InjectedNavbar) {
      imports.addAll(_findImports(node.leadingItem, path));
      imports.addAll(_findImports(node.middleItem, path));
      imports.addAll(_findImports(node.trailingItem, path));
    } else if (node is InjectedTabBar) {
      for (var tab in node.tabs) {
        imports.addAll(_findImports(tab, path));
      }
    } else {
      imports.addAll(_findImports(node.child, path));
    }

    return imports.toSet().toList(); // Prevent repeated entries
  }

  /// Method that traverses the tree to add imports on the first traversal,
  /// and retrieve imports and write the file the second time
  void _traverseTree(bool isFirstTraversal) async {
    var pageWriter = PBFlutterWriter();

    for (var directory in mainTree.groups) {
      var directoryName = directory.name.snakeCase;
      var flutterGenerator;
      var importSet = <String>[];
      var bodyBuffer, constructorBuffer;
      var isSymbolsDir =
          directory.name == SYMBOL_DIR_NAME && _symbolsSinglePage;

      if (!isFirstTraversal) {
        await Directory('${projectName}/lib/screens/${directoryName}')
            .create(recursive: true);
      }

      // Create single FlutterGenerator for all symbols
      if (isSymbolsDir) {
        flutterGenerator = PBFlutterGenerator(pageWriter);
        bodyBuffer = StringBuffer();
      }

      for (var intermediateItem in directory.items) {
        var fileName = intermediateItem.node.name ?? 'defaultName';

        var name = isSymbolsDir ? SYMBOL_DIR_NAME : fileName;
        var symbolFilePath =
            '${projectName}/lib/screens/${directoryName}/${name.snakeCase}.dart';
        var fileNamePath =
            '${projectName}/lib/screens/${directoryName}/${fileName.snakeCase}.dart';
        // TODO: Need FlutterGenerator for each page because otherwise
        // we'd add all imports to every single dart page. Discuss alternatives
        if (!isSymbolsDir) {
          flutterGenerator = PBFlutterGenerator(pageWriter);
        }

        // Add to cache if node is scaffold or symbol master
        if (intermediateItem.node is InheritedScaffold && isFirstTraversal) {
          PBGenCache().addToCache(intermediateItem.node.UUID, symbolFilePath);
        } else if (intermediateItem.node is PBSharedMasterNode &&
            isFirstTraversal) {
          PBGenCache().addToCache(
              (intermediateItem.node as PBSharedMasterNode).SYMBOL_ID,
              symbolFilePath);
        }

        // Check if there are any imports needed for this screen
        if (!isFirstTraversal) {
          isSymbolsDir
              ? importSet
                  .addAll(_findImports(intermediateItem.node, symbolFilePath))
              : flutterGenerator.imports
                  .addAll(_findImports(intermediateItem.node, fileNamePath));

          // Check if [InheritedScaffold] is the homescreen
          if (intermediateItem.node is InheritedScaffold &&
              (intermediateItem.node as InheritedScaffold).isHomeScreen) {
            var relPath = PBGenCache().getRelativePath(
                '${projectName}/lib/main.dart', intermediateItem.node.UUID);
            pageWriter.writeMainScreenWithHome(intermediateItem.node.name,
                '${projectName}/lib/main.dart', relPath);
          }

          var page = flutterGenerator.generate(intermediateItem.node);

          // If writing symbols, write to buffer, otherwise write a file
          isSymbolsDir
              ? bodyBuffer.write(page)
              : pageWriter.write(page, fileNamePath);
        }
      }
      if (!isFirstTraversal) {
        if (isSymbolsDir) {
          var symbolPath =
              '${projectName}/lib/screens/${directoryName}/symbols.dart';
          importSet.add(flutterGenerator.generateImports());

          var importBuffer = StringBuffer();
          importSet.toSet().toList().forEach(importBuffer.write);

          pageWriter.write(
              (importBuffer?.toString() ?? '') +
                  (constructorBuffer?.toString() ?? '') +
                  bodyBuffer.toString(),
              symbolPath);
        }
        pageWriter.submitDependencies(projectName + '/pubspec.yaml');
      }
    }
  }
}

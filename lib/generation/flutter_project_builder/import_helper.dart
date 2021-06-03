import 'package:parabeac_core/eggs/injected_app_bar.dart';
import 'package:parabeac_core/eggs/injected_tab_bar.dart';
import 'package:parabeac_core/generation/prototyping/pb_dest_holder.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/inherited_scaffold.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/pb_shared_instance.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_intermediate_node.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_layout_intermediate_node.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_gen_cache.dart';
import 'package:parabeac_core/generation/flutter_project_builder/file_writer_observer.dart';
import 'package:recase/recase.dart';

class ImportHelper implements FileWriterObserver {
  final Map<String, String> imports = {};

  /// Traverse the [node] tree, check if any nodes need importing,
  /// and add the relative import from [path] to the [node]
  static Set<String> findImports(PBIntermediateNode node, String path) {
    Set currentImports = <String>{};
    if (node == null) {
      return currentImports;
    }

    String id;
    if (node is PBSharedInstanceIntermediateNode) {
      id = node.SYMBOL_ID;
    } else if (node is PBDestHolder) {
      id = node.pNode.destinationUUID;
    } else {
      id = node.UUID;
    }

    var nodePaths = PBGenCache().getPaths(id);
    // Make sure nodePath exists and is not the same as path (importing yourself)
    if (nodePaths != null &&
        nodePaths.isNotEmpty &&
        !nodePaths.any((element) => element == path)) {
      var paths = PBGenCache().getRelativePath(path, id);
      paths.forEach(currentImports.add);
    }

    // Recurse through child/children and add to imports
    if (node is PBLayoutIntermediateNode) {
      node.children
          .forEach((child) => currentImports.addAll(findImports(child, path)));
    } else if (node is InheritedScaffold) {
      currentImports.addAll(findImports(node.navbar, path));
      currentImports.addAll(findImports(node.tabbar, path));
      currentImports.addAll(findImports(node.child, path));
    } else if (node is InjectedAppbar) {
      currentImports.addAll(findImports(node.leadingItem, path));
      currentImports.addAll(findImports(node.middleItem, path));
      currentImports.addAll(findImports(node.trailingItem, path));
    } else if (node is InjectedTabBar) {
      for (var tab in node.tabs) {
        currentImports.addAll(findImports(tab, path));
      }
    } else {
      currentImports.addAll(findImports(node.child, path));
    }

    return currentImports;
  }

  String getImport(String UUID) {
    if (imports.containsKey(UUID)) {
      return imports[UUID];
    }
    return null;
  }

  void addImport(String import, String UUID) {
    if (import != null && UUID != null) {
      imports[UUID] = import;
    }
  }

  @override
  void fileCreated(String filePath, String fileUUID) {
    if (filePath != null && fileUUID != null) {
      imports[fileUUID] = filePath;
    }
  }

  static String getName(String name) {
    var index = name.indexOf('/');
    // Remove everything after the /. So if the name is SignUpButton/Default, we end up with SignUpButton as the name we produce.
    return index < 0
        ? name
        : name.replaceRange(index, name.length, '').pascalCase;
  }
}

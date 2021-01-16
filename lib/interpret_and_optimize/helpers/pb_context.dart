import 'package:parabeac_core/controllers/main_info.dart';
import 'package:parabeac_core/generation/generators/pb_generation_manager.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_configuration.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_intermediate_node_tree.dart';
import 'package:parabeac_core/interpret_and_optimize/value_objects/point.dart';

class PBContext {
  PBConfiguration configuration;
  Point screenTopLeftCorner, screenBottomRightCorner;
  Map jsonConfigurations;
  PBIntermediateTree tree;

  PBGenerationManager get manager => tree?.generationManager;

  PBContext({this.jsonConfigurations}) {
    assert(jsonConfigurations != null);
    var copyConfig = {}..addAll(jsonConfigurations);
    copyConfig.remove('default');

    configuration = PBConfiguration(
        jsonConfigurations[MainInfo().configurationType], jsonConfigurations);
    configuration.configurations = jsonConfigurations;
  }
}

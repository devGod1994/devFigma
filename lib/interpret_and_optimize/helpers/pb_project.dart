import 'package:parabeac_core/generation/generators/util/pb_generation_project_data.dart';
import 'package:parabeac_core/generation/generators/value_objects/file_structure_strategy.dart/pb_file_structure_strategy.dart';
import 'package:parabeac_core/input/sketch/entities/style/shared_style.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_intermediate_node_tree.dart';

class PBProject {
  String projectName;
  String projectAbsPath;
  List<PBIntermediateTree> forest = [];
  List<SharedStyle> sharedStyles = [];
  FileStructureStrategy _fileStructureStrategy;
  PBGenerationProjectData _genProjectData;

  set genProjectData(PBGenerationProjectData projectData) =>
      _genProjectData = projectData;
  PBGenerationProjectData get genProjectData => _genProjectData;

  set fileStructureStrategy(FileStructureStrategy strategy) =>
      _fileStructureStrategy = strategy;

  FileStructureStrategy get fileStructureStrategy => _fileStructureStrategy;

  PBProject(this.projectName, this.sharedStyles,
      {FileStructureStrategy fileStructureStrategy}) {
    _genProjectData = PBGenerationProjectData();
    _fileStructureStrategy = fileStructureStrategy;
  }
}

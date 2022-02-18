import 'package:parabeac_core/controllers/main_info.dart';
import 'package:parabeac_core/interpret_and_optimize/services/design_to_pbdl/design_to_pbdl_service.dart';
import 'package:pbdl/pbdl.dart';
import 'package:path/path.dart' as p;

class FigmaToPBDLService implements DesignToPBDLService {
  @override
  DesignType designType = DesignType.FIGMA;

  @override
  Future<PBDLProject> callPBDL(MainInfo info) {
    return PBDL.fromFigma(
      info.figmaProjectID,
      key: info.figmaKey,
      oauthKey: info.figmaOauthToken,
      outputPath: p.join(info.genProjectPath, 'lib', 'assets'),
      // Generating all assets inside lib folder for package isolation
      pngPath: p.join(info.genProjectPath, 'lib', 'assets', 'images'),
      exportPbdlJson: info.exportPBDL,
      projectName: info.projectName,
    );
  }
}

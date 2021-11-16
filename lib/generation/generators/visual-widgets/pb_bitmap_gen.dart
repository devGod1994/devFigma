import 'package:parabeac_core/controllers/main_info.dart';
import 'package:parabeac_core/generation/generators/attribute-helper/pb_size_helper.dart';
import 'package:parabeac_core/generation/generators/pb_generator.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_intermediate_constraints.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_intermediate_node.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/inherited_bitmap.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/override_helper.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_context.dart';
import 'package:path/path.dart' as p;

class PBBitmapGenerator extends PBGenerator {
  var _sizehelper;

  PBBitmapGenerator() : super() {
    _sizehelper = PBSizeHelper();
  }

  @override
  String generate(
    PBIntermediateNode source,
    PBContext generatorContext,
  ) {
    var buffer = StringBuffer();
    var imageOverride = OverrideHelper.getProperty(source.UUID, 'image');
    if (imageOverride != null) {
      buffer.write('${imageOverride.propertyName} ?? ');
    }

    buffer.write('Image.asset(');

    var styleOverride = OverrideHelper.getProperty(source.UUID, 'layerStyle');
    if (styleOverride != null) {
      buffer.write('${styleOverride.propertyName} ?? ');
    }

    var boxFit = _getBoxFit(source.constraints);

    var imagePath = source is InheritedBitmap
        ? 'assets/${source.referenceImage}' // Assuming PBDL will give us reference to image in the form of `image/<image_name>.png`
        : ('assets/images/' + source.UUID + '.png');

    buffer.write(
        '\'$imagePath\', ${_sizehelper.generate(source, generatorContext)} $boxFit)');
    return buffer.toString();
  }

  String _getBoxFit(PBIntermediateConstraints constraints) {
    if (constraints.pinLeft &&
        constraints.pinBottom &&
        constraints.pinRight &&
        constraints.pinTop) {
      // In case all pins are set
      return 'fit: BoxFit.contain,';
    } else if (constraints.pinLeft && constraints.pinRight) {
      // In case it has set both horizontal pins
      return 'fit: BoxFit.fitWidth,';
    } else if (constraints.pinBottom && constraints.pinTop) {
      // In case it has set both vertical pins
      return 'fit: BoxFit.fitHeight,';
    } else if ((constraints.pinLeft ^ constraints.pinRight) &&
        (constraints.pinTop ^ constraints.pinBottom)) {
      // In case it has set one pin per side
      return 'fit: BoxFit.none,';
    } else if (constraints.fixedHeight && constraints.fixedWidth) {
      // In case scale is set on both directions
      return 'fit: BoxFit.scaleDown,';
    } else {
      // In case everything is false, scale it on both directions
      return 'fit: BoxFit.fill,';
    }
  }
}

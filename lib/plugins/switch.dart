import 'package:parabeac_core/design_logic/design_node.dart';
import 'package:parabeac_core/generation/generators/pb_generator.dart';
import 'package:parabeac_core/generation/generators/pb_param.dart';
import 'package:parabeac_core/generation/generators/plugins/pb_plugin_node.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/interfaces/pb_injected_intermediate.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_intermediate_node.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_context.dart';
import 'package:parabeac_core/interpret_and_optimize/value_objects/point.dart';

import '../interpret_and_optimize/helpers/pb_context.dart';

class Switch extends PBEgg implements PBInjectedIntermediate {
  Switch(Point topLeftCorner, Point bottomRightCorner, this.UUID,
      {this.currentContext})
      : super(topLeftCorner, bottomRightCorner, currentContext) {
    generator = SwitchGenerator();
  }

  PBContext currentContext;

  final String UUID;


  @override
  void addChild(PBIntermediateNode node) {}

  @override
  void alignChild() {}

  @override
  void extractInformation(DesignNode incomingNode) {}

  @override
  PBEgg generatePluginNode(
      Point topLeftCorner, Point bottomRightCorner, DesignNode originalRef) {
    return Switch(topLeftCorner, bottomRightCorner, UUID,
        currentContext: currentContext);
    // throw UnimplementedError();
  }
}

class SwitchGenerator extends PBGenerator {
  SwitchGenerator() : super();

  @override
  String generate(PBIntermediateNode source) {
    if (source is Switch) {
      var value = PBParam('switchValue', 'bool', false);
      manager.addInstanceVariable(value);
      manager.addConstructorVariable(value);
      manager.addDependencies('list_tile_switch', '^0.0.2');
      manager.addImport('package:list_tile_switch/list_tile_switch.dart');
      var buffer = StringBuffer();
      buffer.write('''ListTileSwitch(
        value: switchValue,
      leading: Icon(Icons.access_alarms),
      onChanged: (value) {
        setState(() {
        switchValue = value;
        });
      },
      visualDensity: VisualDensity.comfortable,
      switchType: SwitchType.cupertino,
      switchActiveColor: Colors.indigo,
      title: Text('Default Custom Switch'),
    ),
   ''');
      return buffer.toString();
    }
    throw UnimplementedError();
  }
}

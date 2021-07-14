import 'package:mockito/mockito.dart';
import 'package:parabeac_core/generation/flutter_project_builder/import_helper.dart';
import 'package:parabeac_core/generation/generators/pb_flutter_generator.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/alignments/padding.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_intermediate_node.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_context.dart';
import 'package:parabeac_core/interpret_and_optimize/value_objects/point.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

class NodeMock extends Mock implements PBIntermediateNode {}

class ContextMock extends Mock implements PBContext {}

void main() {
  group('Calculating dynamic padding size test', () {
    var currentContext, currentChild;
    var currentPadding;

    setUp(() {
      currentContext = ContextMock();
      when(currentContext.screenTopLeftCorner).thenReturn(Point(215, -295));
      when(currentContext.screenBottomRightCorner).thenReturn(Point(590, 955));
      when(currentContext.generationManager)
          .thenReturn(PBFlutterGenerator(ImportHelper()));

      currentChild = NodeMock();
      when(currentChild.currentContext).thenReturn(currentContext);

      ///TODO: Update padding test
      // currentPadding = Padding(Uuid().v4(),
      //     left: 15,
      //     right: 15,
      //     bottom: 15,
      //     top: 15,
      //     currentContext: currentContext);
    });
    test('Calculating dynamic padding size', () {
      currentPadding.addChild(currentChild);
      currentPadding = currentPadding as Padding;
      expect(currentPadding.left, 0.04);
      expect(currentPadding.top, 0.012);
      expect(currentPadding.right, 0.04);
      expect(currentPadding.bottom, 0.012);
    });
  });
}

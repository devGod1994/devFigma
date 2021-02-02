import 'package:mockito/mockito.dart';
import 'package:parabeac_core/controllers/interpret.dart';
import 'package:parabeac_core/input/sketch/helper/sketch_project.dart';
import 'package:test/test.dart';

class MockSketchProject extends Mock implements SketchProject {}

void main() {
  var interpret = Interpret();
  test('Interpret should instantiate', () {
    var nameOfProject = 'test Project';
    interpret = Interpret();
    interpret.init(nameOfProject);
    expect(interpret, isNotNull);
    expect(interpret.projectName, nameOfProject);
  });

  test('Should return a PBIntermediateTree from a SketchNodeTree', () {
    var intermediateTree = interpret.interpretAndOptimize(MockSketchProject());
    expect(intermediateTree, isNotNull);
  });

  test('interpret and optimize method should return a PBIntermediateNode',
      () {});
}

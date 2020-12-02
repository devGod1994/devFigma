import 'package:parabeac_core/controllers/main_info.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/injected_container.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/layouts/column.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/layouts/row.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/layouts/rules/container_constraint_rule.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/layouts/rules/container_rule.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/layouts/rules/layout_rule.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/layouts/rules/stack_reduction_visual_rule.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/layouts/stack.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/layouts/temp_group_layout_node.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_intermediate_node.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_layout_intermediate_node.dart';
import 'package:parabeac_core/interpret_and_optimize/entities/subclasses/pb_visual_intermediate_node.dart';
import 'package:parabeac_core/interpret_and_optimize/helpers/pb_context.dart';
import 'package:parabeac_core/interpret_and_optimize/services/pb_generation_service.dart';
import 'package:quick_log/quick_log.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

/// PBLayoutGenerationService:
/// Inject PBLayoutIntermediateNode to a PBIntermediateNode Tree that signifies the grouping of PBItermediateNodes in a given direction. There should not be any PBAlignmentIntermediateNode in the input tree.
/// Input: PBVisualIntermediateNode Tree or PBLayoutIntermediate Tree
/// Output:PBIntermediateNode Tree
class PBLayoutGenerationService implements PBGenerationService {
  ///The available Layouts that could be injected.
  final List<PBLayoutIntermediateNode> _availableLayouts = [];

  var log = Logger('Layout Generation Service');

  ///[LayoutRule] that check post conditions.
  final List<PostConditionRule> _postLayoutRules = [
    StackReductionVisualRule(),
    ContainerPostRule(),
    ContainerConstraintRule()
  ];

  @override
  PBContext currentContext;

  PBLayoutGenerationService({this.currentContext}) {
    var layoutHandlers = <String, PBLayoutIntermediateNode>{
      'column': PBIntermediateColumnLayout(
        '',
        currentContext: currentContext,
        UUID: Uuid().v4(),
      ),
      'row': PBIntermediateRowLayout('', Uuid().v4(),
          currentContext: currentContext),
      'stack': PBIntermediateStackLayout('', Uuid().v4(),
          currentContext: currentContext),
    };

    for (var layoutType
        in currentContext.configuration.layoutPrecedence ?? ['column']) {
      layoutType = layoutType.toLowerCase();
      if (layoutHandlers.containsKey(layoutType)) {
        _availableLayouts.add(layoutHandlers[layoutType]);
      }
    }

    defaultLayout = _availableLayouts[0];
  }

  ///Going to replace the [TempGroupLayoutNode]s by [PBLayoutIntermediateNode]s

  ///The default [PBLayoutIntermediateNode]
  PBLayoutIntermediateNode defaultLayout;

  PBIntermediateNode extractLayouts(
    PBIntermediateNode rootNode,
  ) {
    try {
      var prototypeNode;

      ///The stack is going to saving the current layer of tree along with the parent of
      ///the layer. It makes use of a `Tuple2()` to save the parent in the first index and a list
      ///of nodes for the current layer in the second layer.
      var stack = <Tuple2<PBIntermediateNode, List<PBIntermediateNode>>>[];
      stack.add(Tuple2(null, [rootNode]));

      while (stack.isNotEmpty) {
        var currentTuple = stack.removeLast();
        currentTuple = currentTuple.withItem2(currentTuple.item2
            .map((currentNode) {
              ///Replacing the `TempGroupLayoutNode`s in the tree by the proper
              ///`PBLayoutIntermediateNode`(`Row`, `Stack`, `Column`).
              if (currentNode is TempGroupLayoutNode) {
                prototypeNode =
                    (currentNode as TempGroupLayoutNode).prototypeNode;
                currentNode = _replaceGroupByLayout(currentNode);
                (currentNode as PBLayoutIntermediateNode).prototypeNode =
                    prototypeNode;
              }

              ///Traversing the rest of the `PBIntermediateNode`Tree by adding the
              ///rest of the nodes into the stack.
              if (_containsChildren(currentNode)) {
                currentNode is PBLayoutIntermediateNode
                    ? stack.add(Tuple2(currentNode, (currentNode).children))
                    : stack.add(Tuple2(currentNode, [currentNode.child]));
              }

              return currentNode;
            })

            ///Remove the `TempGroupLayout` nodes that only contain one node
            .map(_removingUnecessaryGroup)

            ///apply the post condition rules to all the nodes in the
            // .map(_applyPostConditionRules)
            .map(_replaceGroupByContainer)
            .toList());

        var node = currentTuple.item1;
        if (node != null) {
          node is PBLayoutIntermediateNode
              ? node.replaceChildren(currentTuple.item2 ?? [])
              : node.child = (currentTuple.item2.isNotEmpty
                  ? currentTuple.item2[0]
                  : null);
        }
      }
    } catch (e, stackTrace) {
      MainInfo().sentry.captureException(
            exception: e,
            stackTrace: stackTrace,
          );
      log.error(e.toString());
    } finally {
      return rootNode;
    }
  }

  /// If this node is an unecessary temp group, just return the child.
  /// Ex: Designer put a group with one child that was a group
  /// and that group contained the visual nodes.
  PBIntermediateNode _removingUnecessaryGroup(PBIntermediateNode tempGroup) {
    if (tempGroup is TempGroupLayoutNode &&
        tempGroup.children[0] is InjectedContainer) {
      // (tempGroup.children[0] as InjectedContainer).prototypeNode =
      // prototypeNode;
      return tempGroup.children[0];
    }
    return tempGroup;
  }

  PBIntermediateNode _replaceGroupByContainer(PBIntermediateNode tempGroup) {
    if (tempGroup == null) {
      return tempGroup;
    }

    // If we still have a temp group, this probably means this should be a container.
    if (tempGroup is TempGroupLayoutNode) {
      assert(tempGroup.children.length < 2,
          'TempGroupLayout was not converted and has multiple children.');

      var replacementNode = InjectedContainer(
        tempGroup.bottomRightCorner,
        tempGroup.topLeftCorner,
        Uuid().v4(),
        '',
        currentContext: currentContext,
      );
      // replacementNode.prototypeNode = prototypeNode;
      replacementNode.addChild(tempGroup.children.first);
      return replacementNode;
    }
    return tempGroup;
  }

  bool _containsChildren(PBIntermediateNode node) =>
      (node is PBVisualIntermediateNode && node.child != null) ||
      (node is PBLayoutIntermediateNode && node.children.isNotEmpty);

  ///Each of the [TempGroupLayoutNode] could derive multiple [IntermediateLayoutNode]s because
  ///nodes should be considered into subsections. For example, if child 0 and child 1 statisfy the
  ///rule of a [Row] but not child 3, then child 0 and child 1 should be placed inside of a [Row]. Therefore,
  ///there could be many[IntermediateLayoutNodes] derived in the children level of the `group`.
  PBLayoutIntermediateNode _replaceGroupByLayout(TempGroupLayoutNode group) {
    var children = group.children;
    PBLayoutIntermediateNode rootLayout;

    if (children.length < 2) {
      ///the last step is going to replace these layout that contain one child into containers
      return _removingUnecessaryGroup(group);
    }
    children = _arrangeChildren(group);
    rootLayout = children.length == 1
        ? children[0]
        : defaultLayout.generateLayout(children, currentContext, group.name);
    //Applying the `PostConditionRule`s to the generated layout
    _applyPostConditionRules(rootLayout);
    return rootLayout;
  }

  List<PBIntermediateNode> _arrangeChildren(PBLayoutIntermediateNode parent) {
    parent.sortChildren();
    var children = parent.children;
    var childPointer = 0;
    var reCheck = false;

    while (childPointer < children.length - 1) {
      var currentNode = children[childPointer];
      var nextNode = children[childPointer + 1];

      for (var layout in _availableLayouts) {
        if (layout.satisfyRules(currentNode, nextNode) &&
            layout.runtimeType != parent.runtimeType) {
          var generatedLayout;

          if (layout.runtimeType == currentNode.runtimeType) {
            currentNode.addChild(nextNode);
            (currentNode as PBLayoutIntermediateNode)
                .replaceChildren(_arrangeChildren(currentNode));
            generatedLayout = currentNode;
          } else if (layout.runtimeType == nextNode.runtimeType) {
            nextNode.addChild(currentNode);
            (nextNode as PBLayoutIntermediateNode)
                .replaceChildren(_arrangeChildren(nextNode));
            generatedLayout = nextNode;
          }

          /// Generated / Injected Layouts can have no names because they don't derive from a group, which means they would also not end up being a misc. node.
          generatedLayout ??= layout
              .generateLayout([currentNode, nextNode], currentContext, '');
          children
              .replaceRange(childPointer, childPointer + 2, [generatedLayout]);
          childPointer = 0;
          reCheck = true;
          break;
        }
      }
      childPointer = reCheck ? 0 : childPointer + 1;
      reCheck = false;
    }
    return children?.cast<PBIntermediateNode>();
  }

  ///Applying [PostConditionRule]s at the end of the [PBLayoutIntermediateNode]
  PBIntermediateNode _applyPostConditionRules(PBIntermediateNode node) {
    if (node == null) {
      return node;
    }

    for (var postConditionRule in _postLayoutRules) {
      if (postConditionRule.testRule(node, null)) {
        var result = postConditionRule.executeAction(node, null);
        if (result != null) {
          return result;
        }
      }
    }

    // if (node is PBLayoutIntermediateNode && node.children.isNotEmpty) {
    //   node.replaceChildren(
    //       node.children.map((node) => _applyPostConditionRules(node)).toList());
    // } else if (node is PBVisualIntermediateNode) {
    //   node.child = _applyPostConditionRules(node.child);
    // }
    return node;
  }
}

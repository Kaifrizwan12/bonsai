import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:bonsai_core/bonsai_core.dart';
import 'package:test/test.dart';

void main() {
  group('countWidgetsInSubtree', () {
    test(
        'counts a StreamBuilder with a Column and five Text widgets as seven nodes',
        () {
      final unit = parseString(
        content: '''
class Demo {
  dynamic build(dynamic context) {
    return new StreamBuilder(
      builder: (context, snapshot) {
        return new Column(
          children: [
            new Text('1'),
            new Text('2'),
            new Text('3'),
            new Text('4'),
            new Text('5'),
          ],
        );
      },
    );
  }
}
''',
        featureSet: FeatureSet.latestLanguageVersion(),
      ).unit;

      final node = _firstInstanceCreation(unit);

      expect(countWidgetsInSubtree(node), 7);
    });

    test('counts a single Text widget as one node', () {
      final unit = parseString(
        content: '''
class Demo {
  dynamic build(dynamic context) {
    return new Text('hello');
  }
}
''',
        featureSet: FeatureSet.latestLanguageVersion(),
      ).unit;

      final node = _firstInstanceCreation(unit);

      expect(countWidgetsInSubtree(node), 1);
    });

    test('counts an empty Container widget as one node', () {
      final unit = parseString(
        content: '''
class Demo {
  dynamic build(dynamic context) {
    return new Container();
  }
}
''',
        featureSet: FeatureSet.latestLanguageVersion(),
      ).unit;

      final node = _firstInstanceCreation(unit);

      expect(countWidgetsInSubtree(node), 1);
    });

    test(
        'counts a deeply nested Column, Row, Expanded, and three Text widgets as six nodes',
        () {
      final unit = parseString(
        content: '''
class Demo {
  dynamic build(dynamic context) {
    return new Column(
      children: [
        new Row(
          children: [
            new Expanded(
              child: new Text('1'),
            ),
            new Text('2'),
            new Text('3'),
          ],
        ),
      ],
    );
  }
}
''',
        featureSet: FeatureSet.latestLanguageVersion(),
      ).unit;

      final node = _firstInstanceCreation(unit);

      expect(countWidgetsInSubtree(node), 6);
    });
  });
}

InstanceCreationExpression _firstInstanceCreation(CompilationUnit unit) {
  final finder = _FirstInstanceFinder();
  unit.visitChildren(finder);
  return finder.node!;
}

class _FirstInstanceFinder extends RecursiveAstVisitor<void> {
  InstanceCreationExpression? node;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    this.node ??= node;
    if (this.node == node) {
      return;
    }
    node.visitChildren(this);
  }
}

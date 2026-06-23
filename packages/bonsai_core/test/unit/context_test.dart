import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:bonsai_core/bonsai_core.dart';
import 'package:test/test.dart';

void main() {
  group('ContextCallDetector', () {
    test('finds no calls when a build method does not read context', () {
      final detector = _runDetector('''
class Demo {
  dynamic build(dynamic context) {
    return new Container();
  }

  dynamic helper() => new Text('helper');
}
''');

      expect(detector.calls, isEmpty);
      expect(detector.maxDepth, 0);
    });

    test('detects a top-level context watch call with a shallow depth', () {
      final detector = _runDetector('''
class Demo {
  dynamic build(dynamic context) {
    return context.watch('theme');
  }
}
''');

      expect(detector.calls, hasLength(1));
      expect(detector.maxDepth, anyOf(equals(0), equals(1)));
      expect(detector.calls.single.callType, 'watch');
    });

    test('tracks a context watch call nested inside three widgets', () {
      final detector = _runDetector('''
class Demo {
  dynamic build(dynamic context) {
    return new Column(
      child: new Row(
        child: new Expanded(
          child: context.watch('theme'),
        ),
      ),
    );
  }
}
''');

      expect(detector.maxDepth, 3);
    });

    test('records Provider.of calls using the provider_of call type', () {
      final detector = _runDetector('''
class Demo {
  dynamic build(dynamic context) {
    return Provider.of(context);
  }
}
''');

      expect(detector.calls.single.callType, 'provider_of');
    });

    test('detects both read and watch context calls in the same build method',
        () {
      final detector = _runDetector('''
class Demo {
  dynamic build(dynamic context) {
    context.watch('theme');
    context.read('theme');
    return new Container();
  }
}
''');

      expect(detector.calls.map((call) => call.callType),
          containsAll(<String>['watch', 'read']));
    });
  });
}

ContextCallDetector _runDetector(String content) {
  final unit = parseString(
    content: content,
    featureSet: FeatureSet.latestLanguageVersion(),
  ).unit;
  final detector = ContextCallDetector();
  unit.visitChildren(detector);
  return detector;
}

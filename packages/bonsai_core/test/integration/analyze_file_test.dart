import 'package:bonsai_core/bonsai_core.dart';
import 'package:test/test.dart';

void main() {
  group('analyzeFile integration', () {
    test('reports a red or yellow band for the heavy screen fixture', () {
      final result = analyzeFile('test/fixtures/heavy_screen.dart');

      expect(HealthScore.fromMetrics(result).band,
          anyOf(equals('RED'), equals('YELLOW')));
    });

    test('reports a green band for the clean screen fixture', () {
      final result = analyzeFile('test/fixtures/clean_screen.dart');

      expect(HealthScore.fromMetrics(result).band, 'GREEN');
    });

    test('returns parseError true for the broken syntax fixture', () {
      final result = analyzeFile('test/fixtures/broken_syntax.dart');

      expect(result.parseError, isTrue);
    });

    test('detects deep context nesting in the deep context fixture', () {
      final result = analyzeFile('test/fixtures/deep_context.dart');

      expect(result.maxContextDepth, greaterThan(5));
    });
  });
}

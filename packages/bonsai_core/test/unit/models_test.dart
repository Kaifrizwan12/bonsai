import 'package:bonsai_core/bonsai_core.dart';
import 'package:test/test.dart';

void main() {
  group('HealthScore.fromMetrics', () {
    test('returns a red score when blast and depth penalties are severe', () {
      final metrics = FileMetrics(
        filePath: 'a.dart',
        scopes: const [],
        maxBlastScore: 80,
        composabilityRatio: 0.0,
        maxContextDepth: 10,
        leafWidgetCount: 0,
        extractedWidgetCount: 0,
      );

      final score = HealthScore.fromMetrics(metrics);

      expect(score.score, lessThan(10));
      expect(score.band, 'RED');
    });

    test('returns a perfect green score when the metrics are ideal', () {
      final metrics = FileMetrics(
        filePath: 'b.dart',
        scopes: const [],
        maxBlastScore: 0,
        composabilityRatio: 1.0,
        maxContextDepth: 0,
        leafWidgetCount: 0,
        extractedWidgetCount: 0,
      );

      final score = HealthScore.fromMetrics(metrics);

      expect(score.score, 100);
      expect(score.band, 'GREEN');
    });

    test('returns a yellow score when the combined penalty is moderate', () {
      final metrics = FileMetrics(
        filePath: 'c.dart',
        scopes: const [],
        maxBlastScore: 40,
        composabilityRatio: 0.5,
        maxContextDepth: 5,
        leafWidgetCount: 0,
        extractedWidgetCount: 0,
      );

      final score = HealthScore.fromMetrics(metrics);

      expect(score.band, 'YELLOW');
    });

    test('returns a green score for a lightly penalized file', () {
      final metrics = FileMetrics(
        filePath: 'd.dart',
        scopes: const [],
        maxBlastScore: 5,
        composabilityRatio: 0.9,
        maxContextDepth: 1,
        leafWidgetCount: 0,
        extractedWidgetCount: 0,
      );

      final score = HealthScore.fromMetrics(metrics);

      expect(score.band, 'GREEN');
    });

    test('preserves the parse error flag on failed metrics', () {
      final metrics = FileMetrics.parseFailure('broken.dart');

      expect(metrics.parseError, isTrue);
    });

    test('serializes to a flat map with all expected keys', () {
      final metrics = FileMetrics(
        filePath: 'e.dart',
        scopes: const [],
        maxBlastScore: 1,
        composabilityRatio: 0.25,
        maxContextDepth: 2,
        leafWidgetCount: 3,
        extractedWidgetCount: 4,
      );
      final result = AnalysisResult(
        metrics: metrics,
        health: HealthScore.fromMetrics(metrics),
      );

      final json = result.toJson();

      expect(json.keys, hasLength(8));
      expect(
          json.keys,
          containsAll(<String>[
            'file',
            'score',
            'band',
            'blastScore',
            'composability',
            'contextDepth',
            'suggestions',
            'parseError',
          ]));
    });

    test('exposes the empty factory with safe default values', () {
      final metrics = FileMetrics.empty('empty.dart');

      expect(metrics.filePath, 'empty.dart');
      expect(metrics.scopes, isEmpty);
      expect(metrics.maxBlastScore, 0);
      expect(metrics.composabilityRatio, 1.0);
      expect(metrics.maxContextDepth, 0);
      expect(metrics.leafWidgetCount, 0);
      expect(metrics.extractedWidgetCount, 0);
      expect(metrics.parseError, isFalse);
    });

    test('formats the health score using the score and band', () {
      final metrics = FileMetrics(
        filePath: 'f.dart',
        scopes: const [],
        maxBlastScore: 0,
        composabilityRatio: 1.0,
        maxContextDepth: 0,
        leafWidgetCount: 0,
        extractedWidgetCount: 0,
      );

      expect(HealthScore.fromMetrics(metrics).toString(), '100/100 [GREEN]');
    });
  });
}

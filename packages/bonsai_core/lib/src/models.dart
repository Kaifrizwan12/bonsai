library models;

import 'package:meta/meta.dart';

enum ScopeType {
  setState,
  streamBuilder,
  consumer,
  valueListenable,
  blocBuilder,
  selector,
  futureBuilder,
  animatedBuilder,
  other,
}

@immutable
class ScopeInfo {
  final ScopeType type;
  final int line;
  final int column;
  final int widgetCount;
  final int nestingDepth;

  const ScopeInfo({
    required this.type,
    required this.line,
    required this.column,
    required this.widgetCount,
    required this.nestingDepth,
  });
}

@immutable
class ContextCall {
  final String callType;
  final int nestingDepth;
  final int line;

  const ContextCall({
    required this.callType,
    required this.nestingDepth,
    required this.line,
  });
}

@immutable
class FileMetrics {
  final String filePath;
  final List<ScopeInfo> scopes;
  final int maxBlastScore;
  final double composabilityRatio;
  final int maxContextDepth;
  final int leafWidgetCount;
  final int extractedWidgetCount;
  final bool parseError;

  const FileMetrics({
    required this.filePath,
    required this.scopes,
    required this.maxBlastScore,
    required this.composabilityRatio,
    required this.maxContextDepth,
    required this.leafWidgetCount,
    required this.extractedWidgetCount,
    this.parseError = false,
  });

  factory FileMetrics.empty(String filePath) {
    return FileMetrics(
      filePath: filePath,
      scopes: const [],
      maxBlastScore: 0,
      composabilityRatio: 1.0,
      maxContextDepth: 0,
      leafWidgetCount: 0,
      extractedWidgetCount: 0,
      parseError: false,
    );
  }

  factory FileMetrics.parseFailure(String filePath) {
    return FileMetrics(
      filePath: filePath,
      scopes: const [],
      maxBlastScore: 0,
      composabilityRatio: 1.0,
      maxContextDepth: 0,
      leafWidgetCount: 0,
      extractedWidgetCount: 0,
      parseError: true,
    );
  }
}

@immutable
class HealthScore {
  final int score;
  final String band;
  final List<String> suggestions;

  const HealthScore({
    required int score,
    required this.band,
    required this.suggestions,
  })  : assert(band == 'GREEN' || band == 'YELLOW' || band == 'RED'),
        score = score < 0 ? 0 : (score > 100 ? 100 : score);

  factory HealthScore.fromMetrics(FileMetrics m) {
    final double blastPenalty = (m.maxBlastScore / 2).clamp(0, 40).toDouble();
    final double composabilityPenalty =
        ((1 - m.composabilityRatio) * 30).clamp(0, 30).toDouble();
    final double contextDepthPenalty =
        (m.maxContextDepth * 3).clamp(0, 30).toDouble();

    final double penalty =
        blastPenalty + composabilityPenalty + contextDepthPenalty;
    final int score = (100 - penalty).round().clamp(0, 100);
    final String band = score >= 75
        ? 'GREEN'
        : score >= 50
            ? 'YELLOW'
            : 'RED';

    final double highestPenalty = [
      blastPenalty,
      composabilityPenalty,
      contextDepthPenalty,
    ].reduce((a, b) => a > b ? a : b);

    final List<String> suggestions = <String>[];
    if (blastPenalty == highestPenalty && blastPenalty > 20) {
      suggestions.add(
        'Extract widgets inside reactive scopes — blast score is HIGH',
      );
    }
    if (composabilityPenalty == highestPenalty && composabilityPenalty > 15) {
      suggestions.add(
        'Decompose build() into smaller custom widget classes',
      );
    }
    if (contextDepthPenalty == highestPenalty && contextDepthPenalty > 15) {
      suggestions.add(
        'Move context.watch/read calls closer to the root of build()',
      );
    }

    return HealthScore(
      score: score,
      band: band,
      suggestions: suggestions,
    );
  }

  @override
  String toString() => '$score/100 [$band]';
}

@immutable
class AnalysisResult {
  final FileMetrics metrics;
  final HealthScore health;

  const AnalysisResult({
    required this.metrics,
    required this.health,
  });

  Map<String, dynamic> toJson() {
    return {
      'file': metrics.filePath,
      'score': health.score,
      'band': health.band,
      'blastScore': metrics.maxBlastScore,
      'composability': metrics.composabilityRatio,
      'contextDepth': metrics.maxContextDepth,
      'suggestions': health.suggestions,
      'parseError': metrics.parseError,
    };
  }
}

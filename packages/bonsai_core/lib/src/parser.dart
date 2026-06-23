library parser;

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'models.dart';
import 'context_detector.dart';
import 'visitor.dart';

CompilationUnit? parseFile(String path) {
  try {
    final String content = File(path).readAsStringSync();
    final result = parseString(
      content: content,
      featureSet: FeatureSet.latestLanguageVersion(),
    );
    if (result.errors.isNotEmpty) {
      return null;
    }
    return result.unit;
  } catch (_) {
    return null;
  }
}

FileMetrics analyzeFile(String path) {
  final CompilationUnit? unit = parseFile(path);
  if (unit == null) {
    return FileMetrics.parseFailure(path);
  }

  final BonsaiVisitor visitor = BonsaiVisitor();
  unit.visitChildren(visitor);

  final ContextCallDetector contextDetector = ContextCallDetector();
  unit.visitChildren(contextDetector);

  return FileMetrics(
    filePath: path,
    scopes: visitor.scopes,
    maxBlastScore: visitor.maxBlastScore,
    composabilityRatio: visitor.composabilityRatio,
    maxContextDepth: contextDetector.maxDepth,
    leafWidgetCount: visitor.leafWidgetCount,
    extractedWidgetCount: visitor.extractedWidgetCount,
  );
}

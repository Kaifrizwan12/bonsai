import 'dart:convert';

import 'package:bonsai_core/bonsai_core.dart';

class PrettyFormatter {
  void format(List<AnalysisResult> results, int threshold) {
    for (final result in results) {
      final String filename = _formatFilename(result.metrics.filePath);
      final String scoreStr =
          '${result.health.score.toString().padLeft(3)}/100';
      final String line = '$scoreStr ${result.health.band}';
      print('$filename ${_colored(line, result.health.band)}');

      if (result.health.score < threshold) {
        for (final suggestion in result.health.suggestions) {
          print(' -> $suggestion');
        }
      }

      if (result.metrics.parseError) {
        print(' [!] Could not parse file — check for syntax errors');
      }
    }
  }

  String _formatFilename(String path) {
    final String filename =
        path.split('/').isEmpty ? path : path.split('/').last;
    final String truncated =
        filename.length > 45 ? filename.substring(0, 45) : filename;
    return truncated.padRight(45);
  }

  String _colored(String text, String band) {
    switch (band) {
      case 'GREEN':
        return '\u001B[32m$text\u001B[0m';
      case 'YELLOW':
        return '\u001B[33m$text\u001B[0m';
      case 'RED':
        return '\u001B[31m$text\u001B[0m';
      default:
        return text;
    }
  }
}

class JsonFormatter {
  String format(List<AnalysisResult> results) {
    return jsonEncode(results.map((result) => result.toJson()).toList());
  }
}

import 'dart:io';

import 'package:args/args.dart';
import 'package:bonsai_core/bonsai_core.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';

import 'config.dart';
import 'formatter.dart';

class BonsaiRunner {
  Future<int> run(List<String> args) async {
    if (args.contains('--version')) {
      print('bonsai v0.1.0');
      return 0;
    }

    if (args.isEmpty ||
        (args.length == 1 && (args.first == '--help' || args.first == '-h'))) {
      print(_rootUsage());
      return 0;
    }

    if (args.first != 'analyze') {
      if (args.contains('--help') || args.contains('-h')) {
        print(_rootUsage());
        return 0;
      }
      print('Unknown command: ${args.first}');
      return 2;
    }

    return _runAnalyze(args.sublist(1));
  }

  Future<int> _runAnalyze(List<String> args) async {
    final parser = ArgParser()
      ..addOption('format', allowed: ['pretty', 'json'], defaultsTo: 'pretty')
      ..addOption('threshold', defaultsTo: '50', help: 'Min score to pass')
      ..addFlag('exit-code', defaultsTo: false, negatable: false)
      ..addFlag('version', defaultsTo: false, negatable: false)
      ..addFlag('help', abbr: 'h', defaultsTo: false, negatable: false);

    late ArgResults results;
    try {
      results = parser.parse(args);
    } on FormatException catch (error) {
      print(error.message);
      print(parser.usage);
      return 2;
    }

    if (results['help'] == true) {
      print(_analyzeUsage(parser));
      return 0;
    }

    if (results['version'] == true) {
      print('bonsai v0.1.0');
      return 0;
    }

    final String targetPath = results.rest.isEmpty ? 'lib' : results.rest.first;
    final directory = Directory(targetPath);
    if (!directory.existsSync()) {
      print('Error: path not found: $targetPath');
      return 2;
    }

    final BonsaiConfig config = BonsaiConfig.load(Directory.current.path);
    final int threshold = results.wasParsed('threshold')
        ? int.tryParse('${results['threshold']}') ?? 50
        : config.threshold;
    final String format = '${results['format']}';
    final bool exitCodeFlag = results['exit-code'] == true;

    final resultsList = <AnalysisResult>[];
    final root = directory.absolute.path;
    final dartFiles = Glob('**.dart').listSync(root: root);
    final excludePatterns = <String>[
      '**/*.g.dart',
      '**/*.freezed.dart',
      ...config.excludePaths,
    ];

    for (final entity in dartFiles) {
      final String path = entity.path;
      if (!_shouldInclude(path, root, excludePatterns)) {
        continue;
      }

      final metrics = analyzeFile(path);
      final health = metrics.parseError
          ? const HealthScore(
              score: 0,
              band: 'RED',
              suggestions: [],
            )
          : HealthScore.fromMetrics(metrics);
      resultsList.add(AnalysisResult(metrics: metrics, health: health));
    }

    if (format == 'json') {
      print(JsonFormatter().format(resultsList));
      return 0;
    }

    PrettyFormatter().format(resultsList, threshold);
    final passed = resultsList
        .where((result) =>
            !result.metrics.parseError && result.health.score >= threshold)
        .length;
    final failed = resultsList.length - passed;
    print(
        'Analysed ${resultsList.length} files. $passed passed. $failed failed (below threshold $threshold).');

    if (exitCodeFlag && failed > 0) {
      return 1;
    }

    return 0;
  }

  bool _shouldInclude(
      String filePath, String root, List<String> excludePatterns) {
    final String relativePath = filePath.startsWith(root)
        ? filePath.substring(root.length).replaceFirst(RegExp(r'^/'), '')
        : filePath;

    for (final pattern in excludePatterns) {
      if (pattern.isEmpty) {
        continue;
      }
      if (Glob(pattern).matches(relativePath) ||
          Glob(pattern).matches(filePath)) {
        return false;
      }
    }

    return !relativePath.endsWith('.g.dart') &&
        !relativePath.endsWith('.freezed.dart');
  }

  String _rootUsage() {
    return [
      'bonsai v0.1.0',
      '',
      'Static analysis for Flutter widget trees.',
      'bonsai shells out to the bonsai CLI and scores each Dart file it finds.',
      '',
      'Usage:',
      '  bonsai analyze [options] [path]',
      '',
      'Commands:',
      '  analyze   Scan a folder of Dart files and print health scores.',
      '',
      'Examples:',
      '  bonsai analyze lib/',
      '  bonsai analyze --format json lib/',
      '  bonsai analyze --threshold 90 --exit-code lib/',
      '',
      'Tip:',
      '  Put bonsai in your PATH with: dart pub global activate bonsai',
    ].join('\n');
  }

  String _analyzeUsage(ArgParser parser) {
    return [
      'bonsai analyze',
      '',
      'Scans Dart files under a folder, scores each file, and prints a report.',
      'Files ending in .g.dart and .freezed.dart are skipped automatically.',
      '',
      'Usage:',
      '  bonsai analyze [options] [path]',
      '',
      'Options:',
      parser.usage,
      '',
      'How scoring works:',
      '  - pretty output shows colour-coded scores in the terminal',
      '  - json output returns a pure JSON array for tooling',
      '  - --threshold sets the minimum passing score',
      '  - --exit-code makes failing files return exit code 1',
      '',
      'Examples:',
      '  bonsai analyze lib/',
      '  bonsai analyze --format json lib/',
      '  bonsai analyze --threshold 90 --exit-code lib/',
    ].join('\n');
  }
}

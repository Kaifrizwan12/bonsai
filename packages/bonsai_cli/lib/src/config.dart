import 'dart:io';

import 'package:yaml/yaml.dart';

class BonsaiConfig {
  final int threshold;
  final List<String> excludePaths;

  const BonsaiConfig({
    required this.threshold,
    required this.excludePaths,
  });

  static BonsaiConfig load(String workingDir) {
    final file = File('$workingDir/.bonsai.yaml');
    if (!file.existsSync()) {
      return const BonsaiConfig(threshold: 50, excludePaths: []);
    }

    try {
      final yaml = loadYaml(file.readAsStringSync());
      if (yaml is! YamlMap) {
        return const BonsaiConfig(threshold: 50, excludePaths: []);
      }

      final dynamic thresholdValue = yaml['threshold'];
      final int threshold = thresholdValue is int
          ? thresholdValue
          : int.tryParse('$thresholdValue') ?? 50;

      final dynamic excludeValue = yaml['exclude_paths'];
      final List<String> excludePaths = <String>[];
      if (excludeValue is YamlList) {
        for (final item in excludeValue) {
          excludePaths.add('$item');
        }
      } else if (excludeValue is List) {
        for (final item in excludeValue) {
          excludePaths.add('$item');
        }
      }

      return BonsaiConfig(threshold: threshold, excludePaths: excludePaths);
    } catch (_) {
      return const BonsaiConfig(threshold: 50, excludePaths: []);
    }
  }
}

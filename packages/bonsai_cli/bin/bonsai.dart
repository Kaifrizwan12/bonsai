import 'dart:io';

import 'package:bonsai_cli/src/runner.dart';

Future<void> main(List<String> args) async {
  final runner = BonsaiRunner();
  final exitCode = await runner.run(args);
  exit(exitCode);
}

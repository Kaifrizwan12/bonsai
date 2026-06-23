library composability;

const List<String> kLeafWidgets = [
  'Text',
  'Icon',
  'Image',
  'NetworkImage',
  'AssetImage',
  'SizedBox',
  'Container',
  'Padding',
  'Divider',
  'VerticalDivider',
  'Center',
  'Align',
  'Expanded',
  'Flexible',
  'Spacer',
  'CircularProgressIndicator',
  'LinearProgressIndicator',
  'IconButton',
  'TextButton',
  'ElevatedButton',
  'OutlinedButton',
  'TextField',
  'TextFormField',
  'Checkbox',
  'Switch',
  'Radio',
  'Tooltip',
  'Ink',
  'InkWell',
  'GestureDetector',
];

double computeComposability(int leafCount, int extractedCount) {
  if (leafCount + extractedCount == 0) {
    return 1.0;
  }

  final double ratio = extractedCount / (leafCount + extractedCount).toDouble();
  if (ratio < 0.0) {
    return 0.0;
  }
  if (ratio > 1.0) {
    return 1.0;
  }
  return ratio;
}

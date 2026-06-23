import 'package:bonsai_core/bonsai_core.dart';
import 'package:test/test.dart';

void main() {
  group('computeComposability', () {
    test('returns one when there are no leaves and no extracted widgets', () {
      expect(computeComposability(0, 0), 1.0);
    });

    test('returns zero when there are only leaf widgets', () {
      expect(computeComposability(10, 0), 0.0);
    });

    test('returns one when there are only extracted widgets', () {
      expect(computeComposability(0, 5), 1.0);
    });

    test('returns the extracted widget ratio for mixed counts', () {
      expect(computeComposability(6, 4), closeTo(0.4, 0.0001));
    });

    test('keeps the result within the inclusive zero-to-one range', () {
      for (final caseValue in [
        [0, 0],
        [2, 1],
        [10, 3],
        [100, 100],
      ]) {
        final ratio = computeComposability(caseValue[0], caseValue[1]);
        expect(ratio, inInclusiveRange(0.0, 1.0));
      }
    });
  });
}

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:bonsai_core/bonsai_core.dart';
import 'package:test/test.dart';

void main() {
  group('BonsaiVisitor', () {
    test(
        'collects reactive scopes, leaves, extracted widgets, and helper methods in one pass',
        () {
      final unit = parseString(
        content: '''
class Demo {
  dynamic build(dynamic context) {
    setState(() {
      new Text('state');
      new CustomCard();
    });

    return new StreamBuilder(
      builder: (context, snapshot) {
        final builder = () => new SizedBox();
        builder();
        return new Consumer(
          builder: (context, child) {
            return new BlocBuilder(
              builder: (context, state) {
                return new ValueListenableBuilder(
                  builder: (context, value, child) {
                    return new Selector(
                      builder: (context, child) {
                        return new FutureBuilder(
                          builder: (context, snapshot) {
                            return new AnimatedBuilder(
                              builder: (context, child) {
                                return new BlocConsumer(
                                  builder: (context, state) {
                                    return new Consumer2(
                                      builder: (context, child) {
                                        return new GetBuilder(
                                          builder: (controller) {
                                            return new Obx(
                                              builder: () {
                                                return new GetX(
                                                  builder: () {
                                                    return new FancyWidget();
                                                  },
                                                );
                                              },
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  dynamic helper() => new Icon('help');
}
''',
        featureSet: FeatureSet.latestLanguageVersion(),
      ).unit;

      final visitor = BonsaiVisitor();
      unit.visitChildren(visitor);

      expect(visitor.scopes, isNotEmpty);
      expect(
        visitor.scopes.map((scope) => scope.type),
        containsAll(<ScopeType>[
          ScopeType.streamBuilder,
          ScopeType.consumer,
          ScopeType.blocBuilder,
          ScopeType.valueListenable,
          ScopeType.selector,
          ScopeType.futureBuilder,
          ScopeType.animatedBuilder,
          ScopeType.other,
          ScopeType.setState,
        ]),
      );
      expect(visitor.maxBlastScore, greaterThan(0));
      expect(visitor.leafWidgetCount, greaterThan(0));
      expect(visitor.extractedWidgetCount, greaterThan(0));
      expect(visitor.composabilityRatio, inInclusiveRange(0.0, 1.0));
    });
  });
}

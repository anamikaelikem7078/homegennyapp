import 'package:flutter_test/flutter_test.dart';
import 'package:homegennyapp/core/series/series_catalog.dart';
import 'package:homegennyapp/features/rm/domain/models/pipeline_stage.dart';

void main() {
  group('SeriesCatalog', () {
    test('fallback offers only UC / SC / CK for new staff', () {
      expect(SeriesCatalog.fallback.active.map((s) => s.short), ['UC', 'SC', 'CK']);
      expect(SeriesCatalog.fallback.stage25Enabled, isFalse);
    });

    test('find matches either form, and COOK is CK', () {
      expect(SeriesCatalog.fallback.find('COOK')?.short, 'CK');
      expect(SeriesCatalog.fallback.find('ck')?.value, 'COOK');
      expect(SeriesCatalog.fallback.find('UNSKILLED_CARE')?.short, 'UC');
      expect(SeriesCatalog.fallback.find('XYZ'), isNull);
    });

    test('unknown series is shown as-is, never as Driver', () {
      expect(SeriesDisplay.label('XYZ'), 'XYZ');
      expect(SeriesDisplay.label('SKILLED_CARE'), 'Skilled Caretaker');
      expect(SeriesDisplay.code('COOK'), 'CK');
      expect(SeriesDisplay.isPaused('DR'), isTrue);
      expect(SeriesDisplay.isPaused('CK'), isFalse);
    });
  });

  group('StaffSeries', () {
    test('cook is CK with a 1000 deposit', () {
      expect(StaffSeries.cook, 'CK');
      expect(StaffSeries.label('CK'), 'Cook (CK)');
      expect(StaffSeries.depositFor('CK'), 1000);
    });
  });

  group('PipelineStages with Stage 2.5 off', () {
    test('S2 goes straight to S3', () {
      expect(PipelineStages.order, isNot(contains(PipelineStages.s25Assess)));
      expect(PipelineStages.nextStage(PipelineStages.s2Verify), PipelineStages.s3Train);
      expect(PipelineStages.canAdvance(PipelineStages.s2Verify, PipelineStages.s3Train), isTrue);
      expect(PipelineStages.canAdvance(PipelineStages.s2Verify, PipelineStages.s25Assess), isFalse);
    });

    test('staff already in S2.5 can still move out', () {
      const s25 = PipelineStages.s25Assess;
      expect(PipelineStages.canAdvance(s25, PipelineStages.s3Train), isTrue);
      expect(PipelineStages.canAdvance(s25, PipelineStages.deferred), isTrue);
      expect(PipelineStages.canAdvance(s25, PipelineStages.terminal), isTrue);
      expect(PipelineStages.flowFor(s25), contains(s25));
    });

    test('S2.5 column shows only when someone is in it', () {
      expect(PipelineStages.visibleStages(const {}), PipelineStages.order);
      expect(
        PipelineStages.visibleStages(const {'S2_5_ASSESS': ['x']}),
        PipelineStages.orderWithS25,
      );
      expect(
        PipelineStages.visibleStages(const {}, stage25Enabled: true),
        PipelineStages.orderWithS25,
      );
    });
  });
}

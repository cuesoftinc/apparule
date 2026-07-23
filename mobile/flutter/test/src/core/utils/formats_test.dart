import 'package:apparule/src/core/utils/formats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatNaira', () {
    test('renders whole naira with thousands grouping', () {
      expect(formatNaira(4500000), '₦45,000');
      expect(formatNaira(0), '₦0');
      expect(formatNaira(123456700), '₦1,234,567');
    });

    test('keeps kobo decimals when present', () {
      expect(formatNaira(4500050), '₦45,000.50');
    });

    test('negative amounts carry the minus sign', () {
      expect(formatNaira(-4500000), '−₦45,000');
    });

    test('non-NGN currencies prefix the code', () {
      expect(formatNaira(4500000, currency: 'USD'), 'USD 45,000');
    });
  });

  group('formatCm', () {
    test('defaults to inches display (A-9), always one decimal', () {
      expect(formatCm(42.5), '16.7 in');
      expect(formatCm(42), '16.5 in');
    });

    test('cm renders when the unit toggle flips (MI-13), one decimal '
        '(tnum grid idiom)', () {
      expect(formatCm(42.5, MeasureUnit.cm), '42.5 cm');
      expect(formatCm(42, MeasureUnit.cm), '42.0 cm');
    });
  });

  group('displayBound', () {
    test('renders canonical-cm range bounds in the active display unit', () {
      // The height gate band (flows/vault.md §1): 100–230 cm ↔ 39–91 in.
      expect(displayBound(100, MeasureUnit.inch), 39);
      expect(displayBound(230, MeasureUnit.inch), 91);
      expect(displayBound(100, MeasureUnit.cm), 100);
      expect(displayBound(230, MeasureUnit.cm), 230);
      // The ManualMeasureRow default band (canvas error cell):
      // 10–200 cm ↔ 4–79 in.
      expect(displayBound(10, MeasureUnit.inch), 4);
      expect(displayBound(200, MeasureUnit.inch), 79);
    });
  });

  group('formatCount', () {
    test('compact social counts (web parity)', () {
      expect(formatCount(999), '999');
      expect(formatCount(1200), '1.2k');
      expect(formatCount(250000), '250k');
      expect(formatCount(1500000), '1.5m');
    });
  });

  group('humanizeMeasureName', () {
    test('snake_case → Title Case', () {
      expect(humanizeMeasureName('shoulder_width'), 'Shoulder Width');
      expect(humanizeMeasureName('chest'), 'Chest');
    });
  });
}

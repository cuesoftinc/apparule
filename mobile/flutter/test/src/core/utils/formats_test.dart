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
    test('always renders one decimal (tnum grid idiom)', () {
      expect(formatCm(42.5), '42.5 cm');
      expect(formatCm(42), '42.0 cm');
    });

    test('inch display converts at 2.54 (MI-13)', () {
      expect(formatCm(42.5, MeasureUnit.inch), '16.7 in');
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

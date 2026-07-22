import 'package:apparule/src/core/utils/parse_amount.dart';
import 'package:flutter_test/flutter_test.dart';

/// parseAmount (CLASS 8): one parser for C5 budget and the quote sheet —
/// the hinted "45,000" format must parse (D05's defect was a raw
/// int.tryParse rejecting the sheet's own hint).
void main() {
  group('parseAmount', () {
    test('plain digits parse', () {
      expect(parseAmount('45000'), 45000);
    });

    test('the hinted comma format parses (D05)', () {
      expect(parseAmount('45,000'), 45000);
    });

    test('currency symbols, spaces and grouping strip away', () {
      expect(parseAmount('₦ 1,250,000'), 1250000);
      expect(parseAmount('NGN 45 000'), 45000);
    });

    test('decimals survive', () {
      expect(parseAmount('45,000.50'), 45000.50);
    });

    test('empty and unparseable input return null (the CTA gate)', () {
      expect(parseAmount(''), isNull);
      expect(parseAmount('   '), isNull);
      expect(parseAmount('abc'), isNull);
      expect(parseAmount('1.2.3'), isNull);
    });
  });

  group('parseAmountMinor', () {
    test('whole naira become kobo', () {
      expect(parseAmountMinor('45,000'), 4500000);
    });

    test('fractions round to the nearest minor unit', () {
      expect(parseAmountMinor('45,000.505'), 4500051);
    });

    test('null propagates', () {
      expect(parseAmountMinor(''), isNull);
    });
  });
}

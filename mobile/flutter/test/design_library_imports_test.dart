import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Material comes from material_ui, never the SDK's frozen design
/// libraries, and every localization scope carries material_ui's strings.
void main() {
  test('Dart sources use material_ui and its localization delegates', () {
    final sdkDesignImport = RegExp(
      r"^(?:import|export) 'package:flutter/(?:material|cupertino)\.dart'",
      multiLine: true,
    );
    final sdkDelegates = ['AppLocalizations', 'localizationsDelegates'].join(
      '.',
    );
    final offenders = <String>[];
    var scanned = 0;
    const dirs = ['lib', 'test', 'test_goldens', 'integration_test', 'tool'];
    for (final dir in dirs) {
      final root = Directory(dir);
      if (!root.existsSync()) {
        continue;
      }
      for (final file in root.listSync(recursive: true).whereType<File>()) {
        final path = file.path;
        if (!path.endsWith('.dart') || path.startsWith('lib/l10n/generated/')) {
          continue;
        }
        scanned++;
        final source = file.readAsStringSync();
        if (sdkDesignImport.hasMatch(source)) {
          offenders.add('$path imports the SDK design library');
        }
        if (source.contains(sdkDelegates)) {
          offenders.add('$path uses $sdkDelegates');
        }
      }
    }
    expect(scanned, greaterThan(0), reason: 'no Dart sources were read');
    expect(offenders, isEmpty);
  });
}

// Token codegen: design/tokens/apparule.tokens.json →
// lib/src/core/theme/tokens/*.dart (mobile-implementation.md §7).
//
// The JSON artifact (pulled from the Figma `apparule/tokens` variable
// collection) is the reviewed source of truth; the Dart files this tool
// writes are generated output and never hand-edited. Run from
// mobile/flutter/:
//
//   dart run tool/gen_tokens.dart
import 'dart:convert';
import 'dart:io';

const _defaultTokensPath = '../../design/tokens/apparule.tokens.json';
const _outDir = 'lib/src/core/theme/tokens';

void main(List<String> args) {
  final tokensPath = args.isNotEmpty ? args.first : _defaultTokensPath;
  final file = File(tokensPath);
  if (!file.existsSync()) {
    stderr.writeln('tokens file not found: $tokensPath');
    exitCode = 1;
    return;
  }
  final tokens = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  Directory(_outDir).createSync(recursive: true);

  _write('color_tokens.dart', _colorTokens(_section(tokens, 'color')));
  _write('spacing_tokens.dart', _spacingTokens(_section(tokens, 'space')));
  _write('radius_tokens.dart', _radiusTokens(_section(tokens, 'radius')));
  _write('motion_tokens.dart', _motionTokens(_section(tokens, 'duration')));
  _write('z_tokens.dart', _zTokens(_section(tokens, 'z')));
  stdout.writeln('tokens generated into $_outDir');
}

Map<String, dynamic> _section(Map<String, dynamic> tokens, String key) =>
    tokens[key]! as Map<String, dynamic>;

String _header(String source) =>
    '''
// GENERATED CODE — do not modify by hand.
//
// Source: design/tokens/apparule.tokens.json ($source), pulled from the
// Figma variable collection `apparule/tokens` (docs/design.md §2/§7).
// Regenerate from mobile/flutter/ with: dart run tool/gen_tokens.dart
''';

/// `bg-elev` → `bgElev`, `text-2-text` → `text2Text`, `1` → `s1`.
String _fieldName(String token) {
  final parts = token.split('-');
  final buffer = StringBuffer(parts.first);
  for (final part in parts.skip(1)) {
    buffer.write(part[0].toUpperCase() + part.substring(1));
  }
  final name = buffer.toString();
  return RegExp('^[0-9]').hasMatch(name) ? 's$name' : name;
}

String _colorHex(String hex) => '0xFF${hex.substring(1).toUpperCase()}';

String _colorTokens(Map<String, dynamic> colors) {
  final buffer = StringBuffer(_header('color'))
    ..writeln("import 'dart:ui';")
    ..writeln();
  for (final mode in ['light', 'dark']) {
    final className =
        'AppColorTokens${mode[0].toUpperCase()}${mode.substring(1)}';
    buffer
      ..writeln(
        '/// ${mode[0].toUpperCase()}${mode.substring(1)}-mode color '
        'tokens (design.md §2).',
      )
      ..writeln('abstract final class $className {');
    colors.forEach((token, value) {
      final hex = (value as Map<String, dynamic>)[mode]! as String;
      buffer.writeln(
        '  static const Color ${_fieldName(token)} = '
        'Color(${_colorHex(hex)});',
      );
    });
    buffer
      ..writeln('}')
      ..writeln();
  }
  return buffer.toString();
}

String _spacingTokens(Map<String, dynamic> space) {
  final buffer = StringBuffer(_header('space'))
    ..writeln(
      '/// Spacing scale — 4px base grid, no off-scale values '
      '(design.md §2).',
    )
    ..writeln('abstract final class AppSpaceTokens {');
  space.forEach((token, value) {
    buffer.writeln('  static const double ${_fieldName(token)} = $value;');
  });
  buffer.writeln('}');
  return buffer.toString();
}

String _radiusTokens(Map<String, dynamic> radius) {
  final buffer = StringBuffer(_header('radius'))
    ..writeln(
      '/// Radii — 8px cards/sheets, full-round avatars/pills '
      '(design.md §2).',
    )
    ..writeln('abstract final class AppRadiusTokens {');
  radius.forEach((token, value) {
    buffer.writeln('  static const double ${_fieldName(token)} = $value;');
  });
  buffer.writeln('}');
  return buffer.toString();
}

String _motionTokens(Map<String, dynamic> duration) {
  final buffer = StringBuffer(_header('duration'))
    ..writeln(
      '/// Motion durations — MI specs quote exact values '
      '(design.md §2).',
    )
    ..writeln('abstract final class AppDurationTokens {');
  duration.forEach((token, value) {
    buffer.writeln(
      '  static const Duration ${_fieldName(token)} = '
      'Duration(milliseconds: $value);',
    );
  });
  buffer.writeln('}');
  return buffer.toString();
}

String _zTokens(Map<String, dynamic> z) {
  final buffer = StringBuffer(_header('z'))
    ..writeln(
      '/// Z-index layers — nothing renders outside these six '
      '(design.md §2).',
    )
    ..writeln('abstract final class AppZTokens {');
  z.forEach((token, value) {
    buffer.writeln('  static const double ${_fieldName(token)} = $value;');
  });
  buffer.writeln('}');
  return buffer.toString();
}

void _write(String fileName, String contents) {
  // Exactly one trailing newline (eol_at_end_of_file over generated files).
  final normalized = '${contents.trimRight()}\n';
  File('$_outDir/$fileName').writeAsStringSync(normalized);
  stdout.writeln('  wrote $_outDir/$fileName');
}

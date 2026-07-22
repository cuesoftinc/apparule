import 'package:apparule/src/core/theme/theme_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The tri-state theme preference (B7 Appearance): hydrates from the
/// persistence seam, persists every change (the one thing
/// SharedPreferences still carries, §11).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to system and hydrates a stored preference', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'theme_mode': 'dark',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(themeModeControllerProvider), ThemeMode.system);
    // The hydrate is fire-and-forget off build — settle the microtasks.
    await Future<void>.delayed(Duration.zero);
    expect(container.read(themeModeControllerProvider), ThemeMode.dark);
  });

  test('set() switches the mode and persists it', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(themeModeControllerProvider.notifier)
        .set(ThemeMode.light);
    expect(container.read(themeModeControllerProvider), ThemeMode.light);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'light');

    await container
        .read(themeModeControllerProvider.notifier)
        .set(ThemeMode.system);
    expect(prefs.getString('theme_mode'), 'system');
  });
}

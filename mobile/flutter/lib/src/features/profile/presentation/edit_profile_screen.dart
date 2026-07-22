import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/app_bar.dart';
import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/features/profile/domain/profile.dart';
import 'package:apparule/src/features/profile/presentation/edit_profile_view_model.dart';
import 'package:apparule/src/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// C9 — edit profile: display name, bio (the C9 meta line), and the
/// optional X-10 tier-1 profile location ("used to recommend nearby
/// designers", pages.md B7) — the same label + field + helper form
/// idiom as the C13 create-designer frame. Username and email are
/// Google-identity facts and not editable here.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final TextEditingController _displayName = TextEditingController();
  final TextEditingController _bio = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _state = TextEditingController();
  bool _hydrated = false;
  bool _saving = false;

  @override
  void dispose() {
    _displayName.dispose();
    _bio.dispose();
    _city.dispose();
    _state.dispose();
    super.dispose();
  }

  void _hydrate(Profile profile) {
    if (_hydrated) return;
    _hydrated = true;
    _displayName.text = profile.displayName;
    _bio.text = profile.bio ?? '';
    _city.text = profile.location?.city ?? '';
    _state.text = profile.location?.state ?? '';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(editProfileViewModelProvider.notifier)
          .save(
            displayName: _displayName.text,
            bio: _bio.text,
            city: _city.text,
            state: _state.text,
          );
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          // Deep-linked with an empty stack: back to the profile tab.
          const ProfileRoute().go(context);
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(editProfileViewModelProvider);

    return Scaffold(
      appBar: AppTopBar(
        kind: AppTopBarKind.sub,
        title: l10n.profileEditProfile,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            const ProfileRoute().go(context);
          }
        },
      ),
      body: switch (state) {
        AsyncData(:final value?) => _EditForm(
          profile: value,
          displayName: _displayName,
          bio: _bio,
          city: _city,
          state: _state,
          saving: _saving,
          onHydrate: _hydrate,
          onSave: _save,
        ),
        AsyncData() => Center(child: Text(l10n.profileSignedOut)),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _EditForm extends StatelessWidget {
  const _EditForm({
    required this.profile,
    required this.displayName,
    required this.bio,
    required this.city,
    required this.state,
    required this.saving,
    required this.onHydrate,
    required this.onSave,
  });

  final Profile profile;
  final TextEditingController displayName;
  final TextEditingController bio;
  final TextEditingController city;
  final TextEditingController state;
  final bool saving;
  final ValueChanged<Profile> onHydrate;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    onHydrate(profile);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final typography = theme.extension<AppTypography>()!;

    OutlineInputBorder border() => OutlineInputBorder(
      borderRadius: BorderRadius.circular(radii.card),
      borderSide: BorderSide(color: colors.border),
    );

    InputDecoration decoration({String? hint}) => InputDecoration(
      hintText: hint,
      hintStyle: typography.body14.copyWith(color: colors.text2),
      isDense: true,
      filled: true,
      fillColor: colors.bgElev,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      border: border(),
      enabledBorder: border(),
    );

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: typography.body14.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.text,
        ),
      ),
    );

    Widget helper(String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: typography.caption13.copyWith(color: colors.text2),
      ),
    );

    final fieldStyle = typography.body14.copyWith(color: colors.text);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: <Widget>[
        label(l10n.editProfileDisplayName),
        TextField(
          controller: displayName,
          style: fieldStyle,
          decoration: decoration(),
        ),
        helper(l10n.editProfileDisplayNameHelper),
        label(l10n.editProfileBio),
        TextField(
          controller: bio,
          style: fieldStyle,
          decoration: decoration(hint: l10n.editProfileBioHint),
        ),
        helper(l10n.editProfileBioHelper),
        label(l10n.editProfileCity),
        TextField(
          controller: city,
          style: fieldStyle,
          decoration: decoration(),
        ),
        label(l10n.editProfileState),
        TextField(
          controller: state,
          style: fieldStyle,
          decoration: decoration(),
        ),
        helper(l10n.editProfileLocationHelper),
        const SizedBox(height: 24),
        Button(
          label: l10n.editProfileSave,
          loading: saving,
          expand: true,
          onPressed: onSave,
        ),
      ],
    );
  }
}

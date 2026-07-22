import 'package:apparule/src/core/l10n/l10n.dart';
import 'package:apparule/src/core/theme/theme_extensions.dart';
import 'package:apparule/src/core/ui/google_auth_button.dart';
import 'package:apparule/src/features/auth/domain/auth_exception.dart';
import 'package:apparule/src/features/auth/presentation/sign_in_view_model.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// C1 — the single Google-CTA auth screen (flows/auth.md §5, pages.md
/// C1; canvas 167:13): gradient wordmark + tagline, exactly one auth CTA
/// (X-1), and the legal links — the same structure and copy as web's
/// `/signin`.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final spacing = theme.extension<AppSpacing>()!;
    final typography = theme.extension<AppTypography>()!;
    final state = ref.watch(signInViewModelProvider);
    final notice = state.hasError ? _noticeCopy(l10n, state.error) : null;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.s6),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // Gradient wordmark — web signin header parity
                        // (accentStart→accentEnd, the one gradient role);
                        // the canvas C1 frame (167:13) opens on the
                        // wordmark alone — no logo mark above it.
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: <Color>[
                              colors.accentStart,
                              colors.accentEnd,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            l10n.appTitle,
                            style: typography.display32Bold.copyWith(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: spacing.s2),
                        Text(
                          l10n.signInTagline,
                          style: typography.body16.copyWith(
                            color: colors.text2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: spacing.s8),
                        GoogleAuthButton(
                          label: l10n.signInContinueWithGoogle,
                          loading: state.isLoading,
                          onPressed: () => ref
                              .read(signInViewModelProvider.notifier)
                              .continueWithGoogle(),
                        ),
                        if (notice != null) ...<Widget>[
                          SizedBox(height: spacing.s2),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              notice,
                              style: typography.caption13.copyWith(
                                color: colors.text2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: spacing.s6),
                child: const _LegalLinks(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// flows/auth.md §4 → copy. Under-CTA notice, matching web's
  /// GoogleAuthButton status line; the CTA itself is the retry.
  String _noticeCopy(AppLocalizations l10n, Object? error) {
    final code = error is AuthException ? error.code : AuthErrorCode.unknown;
    return switch (code) {
      AuthErrorCode.network => l10n.signInErrorNetwork,
      AuthErrorCode.userDisabled => l10n.signInErrorDisabled,
      // canceled never reaches state (silent return); unknown falls back.
      AuthErrorCode.canceled ||
      AuthErrorCode.unknown => l10n.signInErrorGeneric,
    };
  }
}

/// Legal footer per the legal-link canon: inline links carry a persistent
/// underline (color alone can't distinguish them — WCAG 1.4.1, the same
/// rule web's `/signin` footer follows) and point at the canonical
/// Cuesoft policies.
class _LegalLinks extends StatefulWidget {
  const _LegalLinks();

  @override
  State<_LegalLinks> createState() => _LegalLinksState();
}

class _LegalLinksState extends State<_LegalLinks> {
  static final Uri _termsUri = Uri.parse('https://terms.cuesoft.io');
  static final Uri _privacyUri = Uri.parse('https://privacy.cuesoft.io');

  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = () => _open(_termsUri);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _open(_privacyUri);
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  Future<void> _open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final typography = theme.extension<AppTypography>()!;
    final linkStyle = typography.micro12.copyWith(
      color: colors.link,
      decoration: TextDecoration.underline,
      decorationColor: colors.link,
    );
    return Text.rich(
      TextSpan(
        style: typography.micro12.copyWith(color: colors.text2),
        children: <InlineSpan>[
          TextSpan(text: l10n.signInLegalPrefix),
          TextSpan(
            text: l10n.signInLegalTerms,
            style: linkStyle,
            recognizer: _termsRecognizer,
          ),
          TextSpan(text: l10n.signInLegalAnd),
          TextSpan(
            text: l10n.signInLegalPrivacy,
            style: linkStyle,
            recognizer: _privacyRecognizer,
          ),
          TextSpan(text: l10n.signInLegalSuffix),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

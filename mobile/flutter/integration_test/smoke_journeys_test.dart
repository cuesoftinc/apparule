import 'package:apparule/src/core/ui/button.dart';
import 'package:apparule/src/core/ui/confetti_burst.dart';
import 'package:apparule/src/core/ui/post_card.dart';
import 'package:apparule/src/core/ui/status_pill.dart';
import 'package:apparule/src/features/earnings/data/earnings_repository_fake.dart';
import 'package:apparule/src/features/measurements/data/measurement_repository_fake.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol_finders/patrol_finders.dart';

import 'helpers/journeys.dart';

/// E2E smoke (mobile-implementation.md §8 gate 5): the five patrol
/// journeys over the pages.md §8.4-equivalent critical paths — sign-in,
/// take measurement, place order, view earnings, sign-out — on the dev
/// flavor's fake set. The standing regression net: run NIGHTLY + on
/// dispatch (.github/workflows/mobile-e2e.yml), never per-PR (§8's
/// device-farm cost profile).
///
/// Every assertion is a USER-VISIBLE outcome — a screen reached, data
/// shown — never repository or provider state. Locally:
///
/// ```sh
/// flutter test integration_test --flavor dev -d <device>
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  patrolWidgetTest(
    'sign-in: cold start signed out boots to C1, the fake Google sign-in '
    'hands off to C1b first-action, and skipping lands the seeded home feed',
    config: journeyConfig,
    ($) async {
      await bootJourneyApp($, signedIn: false, firstActionSeen: false);

      // C1 — the single Google CTA (flows/auth.md §5).
      await $('Continue with Google').waitUntilVisible();

      // The fake sign-in resolves instantly; a FIRST sign-in redirects
      // to the C1b interstitial (pages.md C1b).
      await $('Continue with Google').tap();
      await $('Welcome, Kiki 👋').waitUntilVisible();
      await $('Take your first measurement').waitUntilVisible();

      // Skip for now → the home feed, telling the seeded §6 story:
      // kiki's followed designers on the story rail and their posts in
      // the column.
      await $('Skip for now').tap();
      await $('amara.designs').waitUntilVisible();
      await $(PostCard).waitUntilVisible();
    },
  );

  patrolWidgetTest(
    'capture: ➕ → chooser → the five-step guide → front pose → side pose '
    '→ height → processing → results → save → the vault shows the session',
    config: journeyConfig,
    ($) async {
      // First-capture user: no vault seed, so no height on file — the
      // height step interposes and the vault ends with ONE session.
      await bootJourneyApp(
        $,
        measurementRepository: MeasurementRepositoryFake(
          bundle: EmptyVaultSeedBundle(),
        ),
      );
      await $('amara.designs').waitUntilVisible();

      // ➕ → the M-11 create chooser.
      await $(find.bySemanticsLabel('Create')).tap();
      await $('Take measurements').waitUntilVisible();

      // First run → the C6 guide (M-8/M-10), five canvas steps.
      await $('Take measurements').tap();
      await $('Guide A-Z').waitUntilVisible();
      await $('Next').tap();
      await $('Get ready').waitUntilVisible();
      await $('Next').tap();
      await $('Set your phone up').waitUntilVisible();
      await $('Next').tap();
      await $('Strike the pose').waitUntilVisible();
      await $('Next').tap();
      await $('Turn to the side').waitUntilVisible();

      // Into the viewfinder: auto-capture (no shutter) fires the 3-2-1
      // per pose by itself — the journey just watches the pose bar
      // advance front → side (M-10).
      await $('Start capture').tap();
      await $('Pose 1 of 2').waitUntilVisible();
      await $('Pose 2 of 2').waitUntilVisible();

      // Height interposes after Pose 2 (flows/vault.md §1 — nothing on
      // file), gated 100–230 cm. Set it on the MI-13 tape ruler — a
      // centre tap commits exactly 165 cm (mid-band) through a pure
      // pointer gesture. Injected keyboard text is NOT reliable here:
      // the live integration_test binding never registers the test
      // text input (`registerTestTextInput => false`), so enterText
      // rides the debug client--1 path against the device's REAL IME
      // connection — the flutter_test-documented confusion risk, and
      // this suite's CI-proven repro (runs 29977089254/29977634721).
      // Typed entry stays covered by the capture widget tests.
      await $('Your height').waitUntilVisible();
      await $(find.bySemanticsLabel('Height slider')).tap();
      await $('Continue').tap();

      // Processing resolves into results (§4 confidences)…
      await $('Your measurements').waitUntilVisible();
      await $('Save to vault').waitUntilVisible();

      // …and saving lands in C7 with the just-captured session.
      await $('Save to vault').tap();
      await $('Measured today').waitUntilVisible();
      await $('Up to date · 2 measurements').waitUntilVisible();
    },
  );

  patrolWidgetTest(
    'commerce: post detail → request → stepper (snapshot, delivery, '
    'review) → submit → confetti → the order detail reads requested',
    config: journeyConfig,
    ($) async {
      await bootJourneyApp($);
      await $('amara.designs').waitUntilVisible();

      // Explore grid → the seeded ankara post's C4 detail.
      await $(find.bySemanticsLabel('Explore')).tap();
      await $(
        find.bySemanticsLabel(
          'Model in an ankara maxi skirt on the runway',
        ),
      ).tap();
      await $('Request this outfit').waitUntilVisible();

      // C5 step 1 — the vault snapshot picker, newest preselected (D63).
      await $('Request this outfit').tap();
      await $('New request · 1 of 3').waitUntilVisible();
      await $('Pick a measurement snapshot').waitUntilVisible();
      await $('Fresh').waitUntilVisible();
      await $('Continue').tap();

      // Step 2 — delivery pre-fills from the most recent order (§6.3).
      await $('New request · 2 of 3').waitUntilVisible();
      await $('14 Adeola Odeku St').waitUntilVisible();
      await $('Continue').tap();

      // Step 3 — review retells the request, then submit.
      await $('Review your request').waitUntilVisible();
      await $(
        'Ankara maxi skirt with structured waistband — amara.designs',
      ).waitUntilVisible();
      await $('Submit request').tap();

      // Success: the MI-10 confetti burst over "Request sent".
      await $('Request sent').waitUntilVisible();
      await $(ConfettiBurst).waitUntilVisible();

      // View order → C8 detail in the requested state.
      await $('View order').tap();
      await $(
        find.descendant(
          of: find.byType(StatusPill),
          matching: find.text('Requested'),
        ),
      ).waitUntilVisible();
    },
  );

  patrolWidgetTest(
    'earnings: a designer session reaches C14 with the seeded balances, '
    'and a payout request MOVES the balance into a processing row',
    config: journeyConfig,
    ($) async {
      // The §6 designer perspective: amara.designs carries the ratified
      // C14 canvas ledger (₦82,500 available / ₦45,000 escrow).
      await bootJourneyApp(
        $,
        earningsRepository: EarningsRepositoryFake(
          viewer: 'amara.designs',
          resolveDelay: Duration.zero,
        ),
      );
      await $('amara.designs').waitUntilVisible();

      // Profile tab → B7 settings → the creator section's earnings row.
      await $(find.bySemanticsLabel('Profile')).tap();
      await $(find.byTooltip('Settings')).tap();
      await $.scrollUntilVisible(finder: $('Earnings & payouts'));
      await $('Earnings & payouts').tap();

      // C14 — the seeded summary cards.
      await $('₦82,500').waitUntilVisible();
      await $('₦45,000').waitUntilVisible();

      // Request the payout (top-bar ⋯ → confirm sheet). The released
      // balance MOVES: available zeroes, processing absorbs it.
      await $(find.byTooltip('Request payout')).tap();
      await $('Request payout').waitUntilVisible();
      await $(find.widgetWithText(Button, 'Request payout')).tap();
      await $('₦0').waitUntilVisible();
      await $('₦127,500').waitUntilVisible();
      await $.scrollUntilVisible(finder: $('−₦82,500'));
    },
  );

  patrolWidgetTest(
    'sign-out: Settings → Account & data → Log out purges the session '
    'and lands back on C1',
    config: journeyConfig,
    ($) async {
      await bootJourneyApp($);
      await $('amara.designs').waitUntilVisible();

      // Profile tab → B7 settings → Account & data (the danger ladder
      // screen — log out lives here).
      await $(find.bySemanticsLabel('Profile')).tap();
      await $(find.byTooltip('Settings')).tap();
      await $.scrollUntilVisible(finder: $('Account & data'));
      await $('Account & data').tap();
      await $.scrollUntilVisible(finder: $('Log out'));

      // Sign out → the live redirect lands C1 (flows/auth.md §2).
      await $('Log out').tap();
      await $('Continue with Google').waitUntilVisible();
    },
  );
}

/// A-10 measurement vocabulary (decisions.md; canonical tables in
/// flows/vault.md §2) — the tailor's field sets are the product
/// vocabulary for EVERY method: manual tape entry and camera capture
/// alike (A-10b). The customer's template selects the set; it lives on
/// the profile but the vocabulary itself is measurements domain.
library;

/// Selects which tailor-sourced field set measuring offers. Null (on the
/// profile) interposes the one-time chooser.
enum MeasurementTemplate { women, men }

/// One measure with its advisory sanity range in cm — the client twin of
/// the server-side per-measure table (flows/vault.md §2: out-of-range
/// prompts a double-check, never a hard block).
typedef ManualMeasureSpec = ({String name, double min, double max});

/// The canonical A-10 templates — flows/vault.md §2 [Decided 2026-07-25:
/// field list collected from a practicing Nigerian tailor]. The 7
/// measures shared by both templates carry identical ranges. Labels
/// render by humanizing the snake_case name.
const Map<MeasurementTemplate, List<ManualMeasureSpec>> kManualTemplates =
    <MeasurementTemplate, List<ManualMeasureSpec>>{
      MeasurementTemplate.women: <ManualMeasureSpec>[
        (name: 'shoulder', min: 30, max: 60),
        (name: 'bust', min: 60, max: 160),
        (name: 'under_bust', min: 55, max: 140),
        (name: 'bust_span', min: 12, max: 30),
        (name: 'waist', min: 50, max: 150),
        (name: 'shoulder_to_bust_point', min: 18, max: 40),
        (name: 'shoulder_to_under_bust', min: 25, max: 50),
        (name: 'shoulder_to_waist', min: 30, max: 60),
        (name: 'half_length', min: 30, max: 70),
        (name: 'waist_to_knee', min: 40, max: 75),
        (name: 'gown_length', min: 90, max: 170),
        (name: 'skirt_length', min: 40, max: 120),
        (name: 'trouser_length', min: 80, max: 120),
        (name: 'thigh', min: 40, max: 90),
        (name: 'knee', min: 25, max: 60),
        (name: 'sleeve_length', min: 15, max: 70),
        (name: 'sleeve_width', min: 20, max: 50),
      ],
      MeasurementTemplate.men: <ManualMeasureSpec>[
        (name: 'shoulder', min: 30, max: 60),
        (name: 'chest', min: 70, max: 160),
        (name: 'waist', min: 50, max: 150),
        (name: 'top_length', min: 55, max: 100),
        (name: 'thigh', min: 40, max: 90),
        (name: 'hip', min: 70, max: 160),
        (name: 'knee', min: 25, max: 60),
        (name: 'shin', min: 20, max: 50),
        (name: 'waist_to_knee', min: 40, max: 75),
        (name: 'trouser_length', min: 80, max: 120),
        (name: 'trouser_inseam', min: 60, max: 95),
        (name: 'biceps', min: 20, max: 50),
        (name: 'sleeve_length', min: 15, max: 70),
        (name: 'neck', min: 25, max: 55),
      ],
    };

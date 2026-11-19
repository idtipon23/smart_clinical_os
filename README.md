# Smart Clinical OS

Flutter clinic workflow for registration, general medical consultation,
clinical records, follow-up, and population reporting. NCD monitoring remains
available as a focused module.

## Configure Supabase

The app requires a Supabase project configured at build/run time; credentials
for the source project are not included. Supply the customer's URL and
publishable (anon) key:

```shell
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-publishable-key
```

## Deploy to Vercel

`vercel.json` builds and serves the Flutter web app. In the Vercel project, add
these environment variables under **Settings > Environment Variables** for each
target environment you use (Preview and Production):

- `SUPABASE_URL`: the Supabase project URL, such as
  `https://your-project.supabase.co`
- `SUPABASE_ANON_KEY`: the Supabase publishable (anon) key

The Vercel build script passes both values to Flutter as `--dart-define`.
Redeploy after changing them. These values are included in the public web app;
use only the publishable/anon key, never a Supabase `service_role` key. Keep
LINE provider secrets in Supabase Edge Function secrets for `line-notifier`,
not in Vercel or the client app.

Gemini requests run only after a clinician explicitly clicks an AI action.
Deploy the two Supabase Edge Functions separately from the Flutter/Vercel
deployment:

```shell
supabase functions deploy ai-workup-suggest --project-ref <project-ref>
supabase functions deploy ai-medication-safety --project-ref <project-ref>
```

Set `GEMINI_API_KEY` as a Supabase Edge Function secret; optionally set
`GEMINI_MODEL` to a supported Gemini Flash model. The default is
`gemini-2.5-flash`. Never put the Gemini key in Vercel or a Flutter
`--dart-define`. Both functions require a valid Supabase user session and return
structured JSON.

Stage 1 is the **ขอคำแนะนำการตรวจเพิ่มเติม (AI Workup)** action in the general
consultation screen. It returns red flags, differential considerations,
recommended physical exams, and investigations; it does not recommend
medications. Stage 2 is the **ตรวจทานความปลอดภัยของยา (AI)** action in the OPD
prescription form. It reviews allergies/cross-allergies, interactions,
comorbidities, and dose-related concerns. It does not prescribe, change a
prescription, or calculate pediatric doses. Closing an Encounter does not call
AI.

The client and Edge Functions allowlist only age, gender, V/S, complaints,
underlying diseases, drug allergies, current medications, recent labs, and new
prescriptions. Before invoking an Edge Function, the client removes identifiers
from the selected patient profile and scrubs common ID/phone/address patterns;
each Edge Function independently re-allowlists the fields and scrubs those
patterns again. Review free text before confirming; AI output remains advisory
and must be checked by the clinician. Images are not sent in either stage.

Use real patient information only where the clinic has approved this external
processing and applicable privacy requirements are met.
In the app, open **ปรึกษา Gemini (การแพทย์ทั่วไป)**, select a patient, enter
the consultation details, and explicitly choose **ขอคำแนะนำการตรวจเพิ่มเติม
(AI Workup)**. Stage 2 is available in the OPD prescription form after entering
a diagnosis and prescription.

## Prepare the database for OPD encounters

Before deploying the clinical workflow, run the SQL migrations in
`supabase/migrations/` in filename order in the SQL Editor for the intended
Supabase project. The OPD migration
[`20261119134500_unify_consultation_opd_encounters.sql`](supabase/migrations/20261119134500_unify_consultation_opd_encounters.sql)
expects the
existing `opd_visits`, `vital_signs`, `lab_results`, and `staff_notes` tables;
it is a feature migration, not a complete database setup. Existing OPD visits
are marked closed. New consultations create open encounters, and vital signs,
lab results, imaging results, and related staff notes are linked to an
encounter. The patient-history migration adds medication/food allergy status
and medication-risk-condition fields; legacy patients default to
“unknown/unscreened,” not “no allergy.” Verify the target project and back up
its database before applying migrations.

This codebase expects the existing table/view names and columns used by its
repositories, including `patients`, `vital_signs`, `cdss_events`, and
`staff_notes`. The included migrations extend the existing schema; they are
not a complete database setup. Provision and verify the full schema, storage
policies, tenant isolation, and the `line-notifier` Edge Function in each
customer project before deployment.

## Clinic medication and procedure catalog

After confirming the target Supabase project and backing up its database, run
the migrations in filename order. This includes
[`20261119152000_clinic_catalogs_and_opd_orders.sql`](supabase/migrations/20261119152000_clinic_catalogs_and_opd_orders.sql),
which adds facility-scoped medication/procedure catalogs and structured OPD
fields. Its nullable `ai_final_review` column is retained for compatibility
with databases where the earlier workflow migration has already run; the
two-stage AI workflow no longer reads or writes that field.

The catalog tables are not shipped with clinic-specific prices or stock.
Populate them using each facility's approved formulary and procedure list,
after verifying facility scoping and existing catalog rows. Do not reuse
another clinic's prices. Verify NLEM editions and drug-specific pediatric dose
references with a qualified clinician before relying on catalog notes;
pediatric automatic dose calculation remains disabled unless verified
drug-specific rules and an IBW protocol are configured.

Patient communications continue to use the existing `line_user_id` mapping
and `line-notifier` function. Do not remove or rename these interfaces if
maintaining the NCDS Voice/LINE workflow.

## Clinical scope

The general consultation workspace records chief complaint, onset, symptoms,
medical history, medicines, allergies, and available observations. It flags
selected warning symptoms and missing information for staff review; it does
not diagnose or prescribe. Final assessment and treatment remain the
responsibility of the treating professional.

## Run and test

```shell
flutter pub get
flutter test
```

Android and iOS application ID: `com.smartclinical.os`. Confirm ownership and
availability of this identifier before publishing store releases.

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

For Gemini clinical suggestions, add `GEMINI_API_KEY` as a Vercel environment
variable for Preview and Production, then redeploy. The key is used only by the
server-side `/api/gemini-consult` function and must not be added as a Flutter
`--dart-define`. The function uses `gemini-3.5-flash-lite`, requires a signed-in
Supabase user, and sends the consultation fields to Google's Gemini API after
the user confirms. The app does not send selected-patient identifiers, but
free-text fields are forwarded as entered; remove names, IDs, phone numbers,
and other identifying details before sending. AI output is advisory, is not
saved automatically, and must be reviewed by a clinician.
Use real patient information only where the clinic has approved this external
processing and applicable privacy requirements are met.
In the app, open **ปรึกษา Gemini (การแพทย์ทั่วไป)**, select a patient, enter
the consultation details, and choose **ส่งปรึกษา Gemini 3.5 Flash Lite**.

This codebase expects the existing table/view names and columns used by its
repositories, including `patients`, `vital_signs`, `cdss_events`, and
`staff_notes`. It does not currently include customer-specific database
migrations or RLS setup. Provision and verify the schema, storage policies,
tenant isolation, and the `line-notifier` Edge Function in each customer
project before deployment.

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

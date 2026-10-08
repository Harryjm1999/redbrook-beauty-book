# Redbrook Clinic for iOS

A native SwiftUI app that rebuilds the Lovable web app screen for screen and talks to the
same Lovable Cloud (Supabase) database. Patients, bookings, treatments and staff roles are
shared, so a booking made in the app shows up on the website and in the clinic diary straight away.

The web app in the rest of this repo is untouched; Lovable never edits anything in `ios/`.

## What's in the app

| Website page | In the app |
| --- | --- |
| Home | **Home** tab |
| Treatments & Fees | **Treatments** tab |
| About Us, Contact | **More** tab |
| Sign in / Sign up | Shown on the **Book In** and **Appointments** tabs until you sign in, and from **More** |
| Book (request an appointment) | **Book In** tab |
| My Appointments (bookings, cancel, contact details) | **Appointments** tab |
| Clinic Diary (calendar, slot blocking, requests, upcoming) | **More → Clinic Diary**, and a button on Appointments, for staff only |
| redbrookclinic.com Privacy Policy and Records Management Policy | Their own screens, linked at the bottom of every screen and under **More → Policies** |

Added for the App Store:

- **Delete account** on the Appointments tab (Apple requires it for any app with sign-up).
  It needs a small database function first; see "One-off database change" below.
- Opening hours, slots and appointment times always use UK time, even if the phone is set to another time zone.
- Tap-to-open in Apple Maps for the clinic address, and tap-to-call/email for patients in the diary.

Left out on purpose:

- **Continue with Google.** Google blocks its sign-in page inside apps unless it is set up as a
  native iOS client, and Apple then also requires Sign in with Apple. Patients sign in with email
  and password, which works for every existing account created that way. Accounts created with
  Google on the website can't sign in to the app yet.

## Keeping it in step with Lovable

Both the app and the website read the same database, so treatments, prices, bookings and blocked
days you change on the website appear in the app immediately with no app update.

Screen layouts and wording are separate copies. When you change a page in Lovable, ask in the
project to "carry over the latest Lovable changes to the iOS app" and the change will be ported
into `ios/`, then shipped in the next App Store update.

## One-off database change (needed for Delete account)

Paste this into the Lovable chat for this project:

> Add a Postgres function `public.delete_my_account()` (security definer, search_path public)
> that raises an exception if `auth.uid()` is null and otherwise runs
> `delete from auth.users where id = auth.uid();`. Revoke execute from public and anon and grant
> execute to authenticated. Don't change anything else.

Profiles and bookings are removed automatically because they already use `ON DELETE CASCADE`.

## Publishing without a Mac (recommended)

The **iOS release to TestFlight** workflow (`.github/workflows/ios-release.yml`) builds, signs
and uploads the app from GitHub's Macs. Apple manages the signing certificate in the cloud, so
there is nothing to install. You need a paid Apple Developer Program membership.

One-off setup, all in a web browser:

1. **Find your Team ID**: [developer.apple.com/account](https://developer.apple.com/account) →
   *Membership details* → *Team ID* (10 characters).
2. **Create an API key**: [App Store Connect](https://appstoreconnect.apple.com) → *Users and Access*
   → *Integrations* → *App Store Connect API* → *Team Keys* → **+**. Name it "GitHub", give it the
   **Admin** role (needed for cloud signing), and click *Generate*. Note the **Key ID** and the
   **Issuer ID** shown above the list, then **Download API Key** (a `.p8` file; Apple only lets you
   download it once).
3. **Register the bundle ID**: developer.apple.com → *Certificates, IDs & Profiles* → *Identifiers*
   → **+** → *App IDs* → *App*. Description "Redbrook Clinic", Bundle ID *Explicit*
   `uk.co.redbrookclinic.app`, no extra capabilities. If that ID is taken, pick another and change
   `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` to match.
4. **Create the app record**: App Store Connect → *Apps* → **+** → *New App*. Platform iOS, name
   "Redbrook Clinic", primary language English (UK), the bundle ID from step 3, SKU `redbrook-ios`.
5. **Add four repository secrets**: GitHub repo → *Settings* → *Secrets and variables* → *Actions*
   → *New repository secret*:
   - `APPLE_TEAM_ID`: the Team ID from step 1
   - `APP_STORE_CONNECT_KEY_ID`: the Key ID from step 2
   - `APP_STORE_CONNECT_ISSUER_ID`: the Issuer ID from step 2
   - `APP_STORE_CONNECT_PRIVATE_KEY`: open the `.p8` file in a text editor and paste all of it,
     including the `BEGIN` and `END` lines

Each release:

1. GitHub repo → *Actions* → **iOS release to TestFlight** → *Run workflow* (on `main`).
   (GitHub only offers this button once the workflow is merged into `main`.)
2. When it goes green, the build shows in App Store Connect → *TestFlight* after Apple's
   processing (usually 5 to 30 minutes). Install the TestFlight app on your iPhone to try it.
3. Fill in the listing and submit, as described in "Publishing to the App Store" below (skip its
   Xcode steps 1 and 2). For screenshots without a Mac, take them on your iPhone from the
   TestFlight build.

Build numbers come from the workflow run number, so every upload is unique. Raise
`MARKETING_VERSION` in `project.yml` (e.g. to 1.1) for each new App Store version.

## Building on your Mac (optional)

You need a Mac with Xcode 16.4 or newer and an Apple Developer Program membership.

1. Install XcodeGen once: `brew install xcodegen` (install Homebrew from https://brew.sh first if needed).
2. Get the code: `git clone https://github.com/Harryjm1999/redbrook-beauty-book.git`, or `git pull` if you already have it.
3. Generate the Xcode project: `cd redbrook-beauty-book/ios && xcodegen generate`.
4. Open `ios/Redbrook.xcodeproj` in Xcode. It downloads the Supabase package on first open.
5. Select the **Redbrook** target → **Signing & Capabilities**, tick *Automatically manage signing*
   and choose your team. If the bundle ID `uk.co.redbrookclinic.app` is taken, change it to
   something unique to you (for example `uk.co.redbrookclinic.ios`).
6. Pick an iPhone simulator or your own iPhone and press Run (⌘R).

Run `xcodegen generate` again whenever files are added to `ios/`. The generated
`Redbrook.xcodeproj` is not committed; `project.yml` is the source of truth.

## Publishing to the App Store

1. In [App Store Connect](https://appstoreconnect.apple.com) → **Apps** → **+** → **New App**:
   platform iOS, name "Redbrook Clinic", language English (UK), the bundle ID from step 5, any SKU.
2. In Xcode choose **Any iOS Device (arm64)**, then **Product → Archive**. When the Organizer opens,
   click **Distribute App → App Store Connect → Upload**.
3. Once processing finishes (you'll get an email), install it through **TestFlight** and try every
   screen on a real iPhone, including booking, cancelling and the clinic diary with a staff account.
4. Fill in the App Store listing:
   - **Screenshots**: 6.9" iPhone (1320 × 2868). Take them from the iPhone 16 Pro Max simulator with ⌘S.
   - **Description, keywords, support URL** (the website works as the support URL).
   - **Privacy Policy URL**: `https://www.redbrookclinic.com/privacy`.
   - **App Privacy**: Contact Info (name, email address, phone number), Health & Fitness → Health
     (appointment notes can include medical history) and User Content (other appointment notes), all
     *linked to the user*, used for *App Functionality*, *not* used for tracking.
   - **Age rating**: answer the questionnaire; medical/treatment information is "infrequent/mild".
   - **App Review Information**: give Apple a working patient login (email and password) so the
     reviewer can see booking. Mention that bookings are requests confirmed by the clinic.
5. Submit for review.

For each later update, raise `MARKETING_VERSION` (e.g. 1.1) and/or `CURRENT_PROJECT_VERSION`
in `project.yml`, regenerate, archive and upload again.

## App icon

`Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` is the website's 512 px icon
scaled up. For a crisp icon, replace it with a 1024 × 1024 PNG with no transparency.

## Project layout

```
ios/
  project.yml                 XcodeGen project definition
  Redbrook/
    App/                      App entry point and tab bar
    Core/                     Supabase client, clinic rules, data models and queries
    Theme/                    Colours, fonts and shared components (matched to src/styles.css)
    Features/                 One folder per screen
    Resources/                Fonts, images, app icon, privacy manifest
```

`.github/workflows/ios.yml` compiles the app on a Mac in GitHub Actions whenever `ios/` changes, then
runs it in an iPhone 16 Pro Max simulator and pushes a screenshot of each screen to the
`ios-screenshots` branch. They are 1320 × 2868, the size App Store Connect asks for.
`.github/workflows/ios-release.yml` signs and uploads it to TestFlight when run by hand.

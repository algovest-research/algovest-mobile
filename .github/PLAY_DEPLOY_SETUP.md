# Google Play deployment setup

The `deploy-play.yml` workflow builds a signed AAB and uploads it to the
**internal testing** track every time code lands on `dev`. Before the first run
you must complete the one-time setup below.

## 1. Create the app in Play Console (manual, once)

Google's API cannot create an app or perform the very first upload. In
[Play Console](https://play.google.com/console):

1. Create the app with package name **`com.algovest.algovest`**.
2. Enable **Play App Signing** (recommended).
3. Build an AAB locally and upload it once by hand to the **Internal testing**
   track, complete the store listing/content rating prerequisites until the
   track accepts releases. Subsequent uploads are automated.

```bash
flutter build appbundle --release   # build/app/outputs/bundle/release/app-release.aab
```

## 2. Generate an upload keystore (once)

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
base64 -i upload-keystore.jks | pbcopy   # copy for the secret below
```

Keep `upload-keystore.jks` somewhere safe and **never commit it** (it's
git-ignored). If you enabled Play App Signing, this is your *upload* key.

## 3. Create a Play service account (once)

1. In Google Cloud, create a service account and enable the
   **Google Play Android Developer API**.
2. Create a JSON key for it.
3. In Play Console → **Users and permissions** → invite the service-account
   email and grant at least **Release to testing tracks** for this app.

## 4. Add repository secrets

Settings → Secrets and variables → Actions → *New repository secret*:

| Secret | Value |
| --- | --- |
| `PLAY_KEYSTORE_BASE64` | base64 of `upload-keystore.jks` (step 2) |
| `PLAY_KEYSTORE_PASSWORD` | keystore store password |
| `PLAY_KEY_PASSWORD` | key password |
| `PLAY_KEY_ALIAS` | key alias (e.g. `upload`) |
| `PLAY_SERVICE_ACCOUNT_JSON` | full contents of the service-account JSON (step 3) |

## Notes

- **Track:** defaults to `internal`. To ship to production, change `track:` to
  `production` in `deploy-play.yml` (consider a staged rollout).
- **Version code:** taken from `github.run_number` so every upload is unique.
  The version *name* still comes from `pubspec.yaml` (`version:`); bump it for
  user-visible releases.
- The workflow also runs `flutter analyze`; a failure blocks the upload.

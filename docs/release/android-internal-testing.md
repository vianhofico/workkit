# Android internal testing handoff

WorkKit can build a release AAB in CI. Publishing to Google Play remains an account-bound external step.

## 1. Create an upload key

Create and securely retain an Android upload keystore. Do not commit it to the repository.

## 2. Configure GitHub Actions secrets

Add these repository secrets:

- `ANDROID_UPLOAD_KEYSTORE_BASE64` — base64 of the upload `.jks` file.
- `ANDROID_UPLOAD_STORE_PASSWORD`
- `ANDROID_UPLOAD_KEY_ALIAS`
- `ANDROID_UPLOAD_KEY_PASSWORD`

## 3. Build the signed AAB

Run the `Android Release AAB` workflow from GitHub Actions. It bootstraps the platform project, runs analyzer/tests, injects signing from environment variables, builds `app-release.aab`, and uploads it as the `workkit-android-aab` workflow artifact.

## 4. Play Console internal testing

Download the AAB artifact, upload it to the Play Console internal testing track, complete the required store/data-safety declarations, invite testers, and run the physical-device checklist from `docs/project/external-validation.md`.

No workflow in this repository invents Play Console credentials or silently publishes on behalf of the repository owner.

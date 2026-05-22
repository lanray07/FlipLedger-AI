# GitHub Xcode Setup

This repo has two GitHub Actions workflows:

- `.github/workflows/ios-build.yml`: builds FlipLedger AI on a GitHub macOS runner without Apple signing secrets.
- `.github/workflows/ios-archive-app-store.yml`: manually archives, exports an IPA, and can upload to App Store Connect using Xcode automatic signing with an App Store Connect API key.

## Build Check

Open GitHub:

1. Go to `Actions`.
2. Select `iOS Build`.
3. Run the workflow, or push to `main`.

This runs:

```sh
xcodebuild \
  -project FlipLedgerAI.xcodeproj \
  -scheme FlipLedgerAI \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## App Store Archive Secrets

Add these repository secrets in GitHub under `Settings > Secrets and variables > Actions`.

Required for archive/export/upload:

- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_API_PRIVATE_KEY_BASE64`

Optional override:

- `APPLE_TEAM_ID` defaults to `5ZP6GV85J6` in the workflow/project.

The workflow uses `xcodebuild -allowProvisioningUpdates` so Xcode can create or update signing assets during CI. You do not need to upload a `.p12` certificate or provisioning profile as GitHub secrets.

## How To Encode The API Key

On macOS:

```sh
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
```

Paste the copied value into `APP_STORE_CONNECT_API_PRIVATE_KEY_BASE64`.

## Manual App Store Upload

Once secrets are set:

1. Go to `Actions`.
2. Select `iOS Archive and App Store Upload`.
3. Click `Run workflow`.
4. Keep `upload_to_app_store` off if you only want an IPA artifact.
5. Turn `upload_to_app_store` on to send the exported IPA to App Store Connect.

The actual App Store Connect app record, subscriptions, screenshots, privacy forms, banking, tax, and agreements still need to be completed in your Apple Developer account.

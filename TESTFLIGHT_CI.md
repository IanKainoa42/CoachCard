# CoachCard TestFlight CI/CD

This repository is wired for a fastlane + GitHub Actions pipeline that uploads CoachCard to TestFlight on pushes to `main`.

## What runs

Workflow:
- `.github/workflows/testflight.yml`

Lane:
- `fastlane ios beta`

## Required GitHub secrets

- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_CONTENT` — base64-encoded App Store Connect `.p8` key contents
- `MATCH_PASSWORD`
- `MATCH_SSH_PRIVATE_KEY` — deploy key with read/write access to the match repo
- `TESTFLIGHT_GROUPS` — optional comma-separated tester groups
- `MATCH_GIT_URL` — optional override if you do not want the default formation-flow certificates repo

## Default signing setup

- Team ID: `WC46K49VFA`
- Bundle ID: `com.ianrichardson.CoachCard`
- Match repo defaults to the existing FormationFlow certificates repo unless overridden by `MATCH_GIT_URL`.

## First-time bootstrap

Run locally on a Mac with Apple access to create the app store profile in the match repo:

```bash
bundle install
bundle exec fastlane ios bootstrap_signing
```

Then commit/push the generated Match repo changes in the external certificates repository.

## Notes

- The workflow uses a build number derived from `GITHUB_RUN_NUMBER`.
- The lane uploads to TestFlight and does not wait for App Store processing.
- To distribute to a specific external group, set `TESTFLIGHT_GROUPS` to a comma-separated list of TestFlight group names.

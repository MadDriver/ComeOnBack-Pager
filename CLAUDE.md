# CLAUDE.md — pager (ComeOnBack Pager)

iPad console app for the ATC Pager platform — the shared workstation board D01
controllers are paged from (the v3 console principal). Part of `~/src/comeonback`
(see root `CLAUDE.md`). SwiftUI, single app target, **no third-party dependencies**,
iPad-only (landscape, full-screen; `UIRequiresFullScreenIgnoredStartingWithVersion=99`
keeps that on iPadOS 26+). Bundle id `co.amalgamated.ComeOnBackPager`, team
`9XKN747L88`, automatic signing, deploy target iOS 16.2. OAuth callback URL scheme:
`comeonback-console`.

## Layout & branches

Bare-worktree repo (`.bare/` + worktrees `main/`, `redesign/`). Remote:
`MadDriver/ComeOnBack-Pager`. v3 (R1 cutover + R2 console parity) is on `main`, pushed.
`ui-redesign` (worktree `redesign/`, unpushed) awaits the user's visual pass — it
predates XcodeGen, so merging it conflicts on the deleted pbxproj: take main's deletion
(`git rm`), then `xcodegen generate` (its new `Theme/` files land via the source glob).

## Generated project (XcodeGen)

**`project.yml` is the source of truth. `ComeOnBack Pager.xcodeproj` is generated and
gitignored** — never hand-edit or commit it. After adding/removing/renaming files or
changing build settings/versions:

```bash
xcodegen generate     # brew install xcodegen (once)
```

Version bumps = `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in `project.yml`.
`LocalLoginComponents.swift` is a gitignored local scratch file, explicitly excluded
from the source glob.

## Build (headless)

Commands assume the machine's active toolchain (`xcode-select -p`) can build iOS —
select one that can (or export `DEVELOPER_DIR`); don't encode machine toolchain state
here.

```bash
xcodegen generate

# Unsigned simulator build (the fast loop; matches CI)
xcodebuild -project "ComeOnBack Pager.xcodeproj" -scheme ComeOnBackPager \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

No test target yet — CI (`.github/workflows/ci.yml`, macos-15 / released Xcode 16) is
an unsigned compile check: generate + the sim build above.

## Deploy

**Production installs come from the App Store (unlisted distribution)** — see Releasing
below. For the fast dev loop, direct install to a paired iPad (dev-cert signed, ~1-year
expiry) still works:

```bash
scripts/deploy-ipad.sh              # list paired devices
scripts/deploy-ipad.sh <name|udid>  # generate → Release device build → devicectl install
```

## Releasing (fastlane + App Store, unlisted)

Mirrors the ios repo. ASC app record: **'Come On Back Pager'** (Apple ID `6463467578`,
SKU = bundle id, pre-existing). Distribution is **unlisted** (install by link, never
searchable) — one-time Apple request form, user-side. ASC creds come from 1Password
via `scripts/pager-release.sh`; signing for CI is **match** (shared certs repo
`lunoho/comeonback-ios-certs`, pager profile added 2026-07-13). All five Actions
secrets are set on `MadDriver/ComeOnBack-Pager`.

```bash
scripts/pager-release.sh verify_asc   # default: ASC auth smoke test
scripts/pager-release.sh beta         # local archive → TestFlight (automatic signing)
scripts/pager-release.sh prepare      # push metadata+screenshots, attach TF build, precheck, STOP
scripts/pager-release.sh submit       # fire App Store Review (the single irreversible step)
scripts/pager-release.sh certs        # one-time/rotation: match bootstrap (read-write)
```

- **Normal flow is CI**: push tag `v<MARKETING_VERSION>` → `release.yml` → match-signed
  build → TestFlight (runner Xcode is release-grade; local beta-Xcode binaries are
  store-ineligible). Promote via `appstore.yml` (`step=prepare`, then `step=submit`
  with `confirm=SUBMIT`) or the local lanes above.
- Version bumps: `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION` in `project.yml`; the
  release tag must match MARKETING_VERSION (guard in release.yml).
- Metadata lives in `fastlane/metadata/**`; review notes need a fresh demo enrollment
  code at submission time (`fastlane/metadata/review_information/notes.txt`).
- `submit`/`prepare` stop-gates match the ios repo (precheck between; manual Release
  click in ASC after approval; `automatic_release:false`).

## Conventions

- Edits go in a worktree dir, never `.bare/`. Secrets are gitignored — never commit them.
- v3 wire contract: `../../api/main/docs/api/v3-mobile-contract.md`. Migration plan:
  `docs/2026-07-09-pager-v3-migration-plan.md` (workspace root `docs/`).
- Keep this file short; link to docs for detail.

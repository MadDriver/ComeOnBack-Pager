#!/usr/bin/env bash
# Ship the pager via fastlane, pulling App Store Connect API-key creds from 1Password.
#
#   scripts/pager-release.sh [lane] [key:value ...]
#
# Lanes: verify_asc (default — auth smoke test) | create_app (one-time ASC app record)
#        | beta (TestFlight, automatic signing) | build_only (signed .ipa, no upload)
#        | certs (one-time match bootstrap — also loads MATCH_* from 1Password)
#        | prepare [build:<n>] [version:<x.y.z>] | submit (fire review — agent-confirmed)
#
# Creds live in the same 1Password item as the ios app (borommakot account, Personal
# vault). The .p8 is read by field id because its label collides with the file
# attachment of the same name. Nothing is written to disk.
set -euo pipefail

OP_ACCOUNT="borommakot.1password.com"
OP_ITEM="op://Personal/AppStore ComeOnBack Fastlane"
OP_P8_FIELD_ID="uqjwrpmvmbqmlpxjr3yrpwsnaq"   # the .p8 PEM STRING field (label is ambiguous)

export OP_ACCOUNT
LANE="${1:-verify_asc}"

cd "$(dirname "$0")/.."

command -v op >/dev/null || { echo "1Password CLI (op) not found." >&2; exit 1; }
command -v fastlane >/dev/null || { echo "fastlane not found (brew install fastlane)." >&2; exit 1; }

echo "Loading App Store Connect API key from 1Password ($OP_ACCOUNT)…"
if ! ASC_KEY_ID="$(op read "$OP_ITEM/Key ID" 2>/dev/null)"; then
  echo "Couldn't read from 1Password ($OP_ACCOUNT). Unlock the desktop app, or run:" >&2
  echo "  eval \$(op signin --account $OP_ACCOUNT)" >&2
  exit 1
fi
ASC_ISSUER_ID="$(op read "$OP_ITEM/Issuer ID")"
ASC_KEY_CONTENT="$(op read "$OP_ITEM/$OP_P8_FIELD_ID")"
export ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_CONTENT

# The certs lane mutates the shared match repo — load the passphrase too. Git auth is
# left ambient locally (this Mac's credential helper has repo access); CI supplies
# MATCH_GIT_BASIC_AUTHORIZATION from secrets instead. NB: constructing that value by
# hand? GNU base64 wraps at 76 chars — pipe through `tr -d '\n'`.
if [ "$LANE" = "certs" ]; then
  MATCH_PASSWORD="$(op read "$OP_ITEM/MATCH_PASSWORD")"
  export MATCH_PASSWORD
fi

echo "Running: fastlane $LANE ${*:2}"
exec fastlane "$LANE" "${@:2}"

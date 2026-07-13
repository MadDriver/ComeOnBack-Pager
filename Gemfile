source "https://rubygems.org"

# Pin fastlane so CI release builds are reproducible (bundler on the runner). Locally
# this repo drives fastlane from Homebrew — macOS system Ruby is too old for the
# modern fastlane dependency graph.
# 2.237.0 changed the Fastfile working directory and broke repo-relative paths on CI;
# pin to the 2.236.x line the ios releases shipped on. Paths in the Fastfile are
# ROOT-anchored anyway, but the pin keeps CI deterministic.
gem "fastlane", "~> 2.236.0"

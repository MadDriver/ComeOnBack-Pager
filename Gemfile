source "https://rubygems.org"

# Pin fastlane to the 2.239 line that CI runs; the committed Gemfile.lock is what
# makes a CI run reproducible (`ruby/setup-ruby` + `bundle install`). Local lanes go
# through Homebrew fastlane instead — `scripts/pager-release.sh` calls `fastlane`
# directly, not `bundle exec` — so keep `brew upgrade fastlane` on this same line.
# (The old 2.236.x pin rested on a wrong diagnosis that 2.237 changed the Fastfile's
# working directory — it didn't; see fastlane/Fastfile. The real reason to move off
# 2.236 is the CVE-2026-35611 fix that shipped in 2.237.)
gem "fastlane", "~> 2.239.0"

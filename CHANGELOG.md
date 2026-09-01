# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.1] - 2026-09-01

### Fixed
- Profiler slash commands are gated on both rspec-rails and test-prof. A
  per-entry `gem:` in the manifest replaces the gem-wide rspec-rails gate, so
  the seven profiler commands used to install into bundles that had test-prof
  but no rspec-rails. 0.3.0 was tagged but never published to rubygems.

## [0.3.0] - 2026-09-01

### Added
- Slash commands as a second artifact kind, installed into `.claude/commands/`:
  seven test-prof profilers (`/fprof`, `/event-prof`, `/rd-prof`, `/tps-prof`,
  `/factory-default-prof`, `/mem-prof`, `/stack-prof`, gated on test-prof via
  the manifest `commands:` section), two ungated RSpec diagnostics
  (`/slowest-specs`, `/bisect-order`), and a `/profile-specs` entry point
  templated for bundles with and without test-prof. Each command carries the
  flag, result interpretation, and a usage example.
- `martian-spec` skill: supporting references extracted from the skill body —
  `data-setup.md` (test-prof decision tables, checklist, `refind:`, red flags,
  symptom table), `profiling.md` (runnable cheat-sheet commands, pointing at
  the slash commands), `structure.md` (ordering convention with annotated
  example) — all three conditional on test-prof — and `parallel-ci.md`
  (runner comparison, per-worker databases, shared-cache namespacing),
  installed unconditionally.
- `martian-spec` skill: `allowed-tools` frontmatter; a "Never hit real
  external APIs" rule with WebMock/VCR notes gated on those gems; a gated
  bcrypt cost snippet; generic flaky-spec diagnostics (factory profiling via
  `ActiveSupport::Notifications`, time-leak and `before(:context)` checks);
  a named-subject convention; a cache-store-aware failsafe checklist.
- `martian-spec` skill: when the bundle lacks test-prof, the installed skill
  instructs the agent to suggest adding it (`bundle add test-prof --group
  test` plus recipe requires) rather than adding it silently.
- `Rakefile` wiring rails-hyperdrive's author-side manifest lint
  (`rake hyperdrive:manifest:check`) and a CI workflow running it.
  `rails-hyperdrive` and `rake` are development-only Gemfile dependencies.

### Changed
- Migrated to the rails-hyperdrive 0.8.0 companion contract. The skill is a
  standalone master template
  (`lib/rails-hyperdrive-martian-spec/hyperdrive/skills/martian-spec/SKILL.md.erb`
  with `references/` alongside it) rendered per-app at install; content varies
  with the consuming app's bundle via `gem?` blocks (test-prof, graphql,
  rspec-sidekiq, sidekiq, webmock, vcr, bcrypt). Old `gem:`/`versions:`
  frontmatter gating moved into a gem-root `hyperdrive.yml`, where the
  requirement rides on the target member
  (`gems: [rspec-rails: ">= 6.0, < 9.0"]` — the `versions:` key is retired).
  Gemspec discovery metadata keys renamed from `rails_hyperdrive_*` to
  `hyperdrive_targets` / `hyperdrive_artifacts` (now `"skill,command"`), the
  keys `hyperdrive:discover` reads since rails-hyperdrive 0.6.
- `martian-spec` skill description rewritten without third-party gem mentions;
  the intro, layer table, and examples generalized (handler example is a plain
  request spec; "Worker spec" is "Job spec").
- `martian-spec` skill: wrong-layer guidance reworded as design-smell signals
  ("flag it, put coverage where the logic lives") instead of extraction
  directives; the duplicate wrong-layer escalation ladder was dropped.
- Renamed the gem from `rails-hyperdrive-rspec` to `rails-hyperdrive-martian-spec`.
  The `RailsHyperdriveRspec` module is now `RailsHyperdriveMartianSpec` and the
  entrypoint is `require "rails-hyperdrive-martian-spec"`. `rails-hyperdrive-rspec`
  0.2.0 remains on rubygems but receives no further releases.

## [0.2.0] - 2026-08-06

### Added
- Initial scaffold of the companion gem.
- `martian-spec` skill targeting `rspec-rails`.
- `martian-spec` skill: "Suite-level speed (CI)" section covering log quieting,
  weakening cryptographic KDFs in test, fair parallelization, and global
  failsafes for leaky state.
- `martian-spec` skill: profiler cheat-sheet mapping each test-prof env flag to
  its tool and the question it answers.
- Gemspec discovery metadata (`rails_hyperdrive_targets`,
  `rails_hyperdrive_artifacts`) so `hyperdrive:discover` finds the gem on
  rubygems before it is bundled.

### Changed
- `martian-spec` skill description: also triggers when implementing a new
  feature or fixing a bug, not only when touching spec files directly.

[Unreleased]: https://github.com/rails-hyperdrive/rails-hyperdrive-martian-spec/compare/v0.3.1...HEAD
[0.3.1]: https://github.com/rails-hyperdrive/rails-hyperdrive-martian-spec/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/rails-hyperdrive/rails-hyperdrive-martian-spec/releases/tag/v0.3.0
[0.2.0]: https://github.com/rails-hyperdrive/rails-hyperdrive-martian-spec/releases/tag/v0.2.0

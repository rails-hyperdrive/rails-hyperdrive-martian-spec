# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Migrated to the rails-hyperdrive 0.5.0 companion contract. The `martian-spec`
  skill moved from `lib/rails-hyperdrive-martian-spec/hyperdrive/skills/` to the
  top-level `skills/` root, and its `gem:`/`versions:` gating moved out of
  SKILL.md frontmatter into a new gem-root `hyperdrive.yml` (still targeting
  `rspec-rails`, `>= 6.0`, `< 9.0`). No behavior change for consuming apps.
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

[Unreleased]: https://github.com/izhanov/rails-hyperdrive-martian-spec/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/izhanov/rails-hyperdrive-martian-spec/releases/tag/v0.2.0

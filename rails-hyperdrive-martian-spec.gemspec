require_relative "lib/rails-hyperdrive-martian-spec/version"

Gem::Specification.new do |spec|
  spec.name        = "rails-hyperdrive-martian-spec"
  spec.version     = RailsHyperdriveMartianSpec::VERSION
  spec.authors     = ["izhanov"]
  spec.email       = ["aibek.izhanov@evilmartians.com"]

  spec.summary     = "Rails Hyperdrive companion gem: RSpec skill for AI coding agents."
  spec.description = <<~DESC
    Companion gem for rails-hyperdrive. Ships the `martian-spec` skill — a procedural,
    model-invoked guide for writing RSpec specs in Rails projects. Installed lazily
    by `bin/rails hyperdrive:init` into `.claude/skills/martian-spec/SKILL.md`.
  DESC
  spec.homepage    = "https://github.com/izhanov/rails-hyperdrive-martian-spec"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"]          = spec.homepage
  spec.metadata["source_code_uri"]       = spec.homepage
  spec.metadata["changelog_uri"]         = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["allowed_push_host"]     = "https://rubygems.org"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.metadata["hyperdrive_targets"]   = "rspec-rails"
  spec.metadata["hyperdrive_artifacts"] = "skill,command"

  spec.files = Dir[
    "lib/**/*",
    "commands/**/*",
    "hyperdrive.yml",
    "LICENSE.txt",
    "README.md",
    "CHANGELOG.md"
  ].reject { |f| File.directory?(f) }

  spec.require_paths = ["lib"]
end

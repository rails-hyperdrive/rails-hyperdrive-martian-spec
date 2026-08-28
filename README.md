# rails-hyperdrive-martian-spec

Companion gem for [rails-hyperdrive](https://github.com/rails-hyperdrive/rails-hyperdrive) — ships the `martian-spec` skill for AI coding agents working with RSpec in Rails projects.

## Install

```ruby
# Gemfile
group :development do
  gem "rails-hyperdrive"
  gem "rails-hyperdrive-martian-spec"
end
```

Then run `bin/rails hyperdrive:init`. The skill is installed to `.claude/skills/martian-spec/SKILL.md` and loaded lazily by Claude Code when relevant.

## License

MIT — see [LICENSE.txt](LICENSE.txt).

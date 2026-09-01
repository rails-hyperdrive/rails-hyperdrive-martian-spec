# Parallel CI: runner choice and setup

## Runner choice matters

- **`parallel_tests`** splits *files* across processes up front (static). The
  slowest file becomes the bottleneck and each worker boots the app separately.
- **`test-queue`** (preferred) forks workers after one boot and hands out
  examples from a shared queue — a free worker grabs the next spec, so slow
  files can't strand a worker, and there's no per-worker re-boot. This is what
  Rails' own Minitest `parallelize` does (fork + distribute), which is why a
  Minitest suite often looks "faster" than a single-process RSpec — it's the
  parallelism, not the framework.

## Per-worker databases

Give each worker its own database so workers never contend — but the setup
differs by runner:

- **`test-queue`** does NOT set `TEST_ENV_NUMBER` (its env vars, e.g.
  `TEST_QUEUE_WORKERS`, control the queue, not worker identity) — it forks
  after boot, so workers inherit the parent's DB connection. The stock
  `rspec-queue` binary has no per-worker hooks; wire a custom runner and
  reconnect in `after_fork`:

  ```ruby
  #!/usr/bin/env ruby
  # bin/test-queue — run as: bin/test-queue spec
  require "test_queue"
  require "test_queue/runner/rspec"

  class Runner < TestQueue::Runner::RSpec
    def after_fork(num)
      db = ActiveRecord::Base.connection_db_config.configuration_hash
      ActiveRecord::Base.establish_connection(db.merge(database: "#{db[:database]}_#{num}"))
    end
  end

  Runner.new.execute
  ```

  Create/load the per-worker schemas once in CI setup before the run.

- **`parallel_tests`** sets `TEST_ENV_NUMBER` per process: suffix the database
  name with it in `database.yml` (SQLite: one file per number), and create the
  databases with `rake parallel:create parallel:load_schema`.

## Shared cache stores under parallel workers

With a shared store (`:redis_cache_store`, memcached) in test, one worker's
`Rails.cache.clear` wipes every other worker's entries. Namespace the store
per worker first, then clear:

```ruby
# config/environments/test.rb
config.cache_store = :redis_cache_store,
  { namespace: "test#{ENV.fetch("TEST_ENV_NUMBER", "")}" }

# spec/rails_helper.rb
config.after { Rails.cache.clear }
```

Under `test-queue` nothing sets `TEST_ENV_NUMBER` — assign it in the custom
runner's `after_fork` above (`ENV["TEST_ENV_NUMBER"] = num.to_s`) so the same
namespacing works there.

## CI sizing

Know your core count first (GitHub-hosted **private** repos get 2 vCPUs,
public get 4) — cache the runtime log for runtime-based balancing.

## Fair queues expose isolation bugs — that's a feature

**A fair queue exposes every latent isolation bug** — specs that only passed
because another file ran first in the same process. It finds real
order-dependence. When a spec fails only under parallelism, run it *alone*
(`rspec path/to/x_spec.rb`) — if it fails there too, it's a self-sufficiency
bug (a missing `require`/constant, or leaked global state), not the runner.

---
name: martian-spec
description: "Writing and reviewing RSpec tests in Rails projects. Use when (1) implementing a new feature or fixing a bug in a Rails app -- the specs that come with it are part of the change, (2) creating new spec files or adjusting existing ones, (3) reviewing test code for anti-patterns, (4) optimizing slow tests, factory performance, or CI queue time, (5) debugging flaky or order-dependent specs. MUST use when working with let_it_be, before_all, factory_bot, spec file organization, or service/model/controller/job spec layer decisions. Covers: RSpec, test-prof, factory_bot, spec layering, CI performance."
---

# RSpec for Rails

A skill for writing fast, well-layered, non-flaky RSpec specs in Rails projects using `factory_bot` and `test-prof`.

## Thinking Prompts

Before writing a test context, ask yourself:

- "Could I test this with a simpler object at a lower layer?" -- if yes, do that instead
- "Am I creating factories just to satisfy the entry point, not the logic?" -- wrong layer
- "Would this test break if I changed the HTTP/GraphQL wrapper?" -- logic is too high
- "Am I stubbing >3 collaborators just to isolate what I'm testing?" -- testing wiring, not behavior
- "Is this setup expensive because the logic lives far from where I'm testing it?" -- push logic down

When reviewing existing specs, scan for performance and layer issues:

- "How many `create` calls run per example vs per file?" -- the #1 speed lever
- "Is there a `before` that could be `before_all`?" -- quick wins first
- "Are any traits used only for their attributes, not their associations?" -- trait cascades are the #1 hidden waste source
- "Are any contexts testing a layer above where the logic lives?" -- structural issue, see Red Flags

Then annotate contexts with `[ok]`/`[warning]`/`[error]`:

- `[ok]` -- belongs in this layer
- `[warning]` -- borderline, signals a design smell
- `[error]` -- wrong layer, should be tested elsewhere

If a handler (controller action, GraphQL resolver, job `perform`) has >3 conditional branches (simple guards don't count), extract to a service. The handler spec gets one smoke test with a mocked service; the service spec gets full coverage.

Before writing a spec with >5 contexts, sketch the describe/context tree and annotate each with `[ok]`/`[warning]`/`[error]`. If >30% are `[warning]` or `[error]`, the code needs refactoring before it needs more tests.

### Layer Selection

| What you're testing | Spec layer | Subject pattern |
|---------------------|------------|-----------------|
| Business rule / computation | Service spec | `described_class.call(...)` |
| DB scope / validation / callback | Model spec | `model.method` or `Model.scope` |
| GraphQL field (thin delegation) | Type spec | `MySchema.execute(query, ...)` |
| GraphQL field with >3 branches | Service spec + type smoke test | Extract first |
| Background job execution | Worker spec | `described_class.new.perform(...)` |
| Job gets enqueued by caller | Caller's spec | `have_enqueued_sidekiq_job` / `have_enqueued_job` |
| HTTP endpoint (REST API) | Request spec | `post "/api/path", params:, as: :json` |

### When logic is already at the wrong layer

| Situation | Action |
|-----------|--------|
| Writing spec for a handler with >3 branches | Extract to service first, then write service spec + handler smoke test |
| Reviewing spec with `[error]`-layer contexts | Flag for extraction, don't add more wrong-layer tests |
| Adding a feature to code that already has wrong-layer tests | Don't compound it — extract what you're touching |
| Can't extract now (time-pressured) | Write minimal handler spec + `# TODO: extract to service — logic doesn't belong here` |

## Quick Reference: Data Setup

### Use `let_it_be` when:

| Situation | Variant | Why |
|-----------|---------|-----|
| Data never changes between examples | `let_it_be(:x) { create(...) }` | Created once, shared across examples |
| Record mutated by code under test | `let_it_be(:x, refind: true)` | `refind: true` does a full `find` after each example (fresh Ruby object); use `let` if mutation is destructive (soft-delete, discard) |
| Static setup (no mocks involved) | `before_all { create(...) }` | Runs once, not per example |

### Keep as `let` when (NOT `let_it_be`):

| Situation | Why |
|-----------|-----|
| Value overridden in nested contexts | `let_it_be` is frozen at creation; nested `let` overrides won't affect it |
| ANY dependency in the chain is overridden in nested contexts | Transitive: if the root is overridden, every dependent that references it must ALL stay as `let` — `let_it_be` records were created with the original dependency |
| Nested context creates records with unique constraints on a shared object | `let_it_be` reuses the same DB record; a nested `create` hitting a unique index raises `RecordNotUnique` |
| Factory or setup writes to Redis/cache | Transaction savepoints only roll back DB state; cache/Redis writes persist across examples |
| References another `let` that varies | Depends on per-context data that `let_it_be` can't see |
| Setup involves mocks, stubs, or test doubles (`double`, `instance_double`, `spy`) | Mocks and doubles are scoped to one example; `let_it_be` leaks them into subsequent examples causing "leaked into another example" errors |
| Time-sensitive logic | `before_all` / `let_it_be` freezes time across all examples and leaks to other files; use `before { travel_to(time) }` |
| `before` block creates records referencing data that sibling contexts override | `before_all` records persist across ALL sibling contexts; if a sibling redefines a dependency, the `before_all` records still reference the original — keep as `before` |

### Pre-conversion checklist: `let` → `let_it_be`

Before converting, verify ALL of these:
- [ ] No nested `let` override of any dependency in the chain
- [ ] No unique constraints on the shared object in nested contexts
- [ ] No Redis/cache writes in the factory or setup
- [ ] Declaration appears AFTER all its `let_it_be` dependencies in source order
- [ ] No model callbacks (`before_commit`, `after_commit`) on created records that implicitly create other persistent records (these survive savepoint rollback and cause unique constraint violations)
- [ ] For `before` → `before_all`: no sibling context overrides any data the block references (records leak across siblings)

**`let_it_be` modifiers:** Prefer `refind: true` over `reload: true` — `reload: true` is a half-measure that re-reads attributes but keeps the same Ruby object, while `refind: true` does a full `Model.find` returning a completely fresh object. When neither modifier works (soft-delete, `discard`), fall back to `let`.

**`refind: true` side-effect:** `refind` issues a `SELECT *` per example. If the spec asserts on SQL events, filter out the reload query.

### Optimization strategies (don't leave speed on the table)

**Use `refind: true` to unlock cascading conversions.** When a record is mutated in nested contexts (e.g., `user.save!`, `record.update!`) but NOT destroyed, use `let_it_be(:record, refind: true)` instead of falling back to `let`. This lets all dependents also become `let_it_be`, saving dozens of factory calls. Only fall back to `let` when the mutation is destructive (soft-delete, discard).

**Use `refind: true` when sibling contexts load the same association.** Without `refind`, `let_it_be` reuses the same Ruby object across all contexts. If context A's `before` creates child records and the example loads the association (e.g., `user.posts`), the association cache persists on the Ruby object even after the records are rolled back. Context B then gets stale cached data instead of querying the DB. `refind: true` returns a fresh Ruby object per example, with no stale association cache.

```ruby
# BEFORE: user mutated in contexts → entire chain stays `let`
let(:user) { create(:user) }
let!(:post) { create(:post, user: user) }
let!(:comment) { create(:comment, post: post) }
let!(:reaction) { create(:reaction, user: user) }

# AFTER: refind on the root unlocks the whole chain
let_it_be(:user, refind: true) { create(:user) }
let_it_be(:post) { create(:post, user: user) }
let_it_be(:comment) { create(:comment, post: post) }
let_it_be(:reaction) { create(:reaction, user: user) }
```

**Convert nested single-context declarations.** A `let` inside a context with 1-2 examples and no nested overrides is safe to convert to `let_it_be`. Don't skip these — a file with 20 contexts × 2 examples = 40 unnecessary factory calls if you only optimize the top level. Scan every `describe`/`context` block.

**Hoist duplicate `let` declarations.** When multiple sibling contexts define identical `let(:x) { create(...) }`, hoist the declaration to the shared parent scope. If the parent uses `let_it_be`, the hoisted declaration can too — one factory call instead of N.

**Convert pure-Ruby declarations.** `let` blocks that build non-DB objects (anonymous classes, schema definitions, static hashes) are always safe to convert to `let_it_be` — no DB rollback concerns.

**Break factory cascades by passing shared objects.** When a factory implicitly creates associations, each `create` spawns redundant records. Pass existing `let_it_be` objects to short-circuit the cascade.

```ruby
# BEFORE: 3 contexts × create(:post) = 3 users + 3 categories created implicitly
let(:post) { create(:post) }

# AFTER: share the parent objects, pass them explicitly
let_it_be(:user) { create(:user) }
let_it_be(:category) { create(:category) }
let_it_be(:post) { create(:post, user: user, category: category) }
```

**Eliminate expensive traits that the spec doesn't need.** Factory traits with associations are hidden cascade sources — each trait association spawns its own dependency tree. Profile factories (e.g., test-prof's `FPROF=1`) and look for factories where `total` >> `top-level`; trace the gap to a trait, then replace the trait with only the explicit attributes the test actually requires.

```ruby
# BEFORE: :with_full_profile creates address + avatar + preferences,
# each cascading to additional records
create(:user, :with_full_profile)

# AFTER: replace trait with the attributes the code under test actually checks
create(:user, status: "active", role: "admin")
```

**Check model scopes when replacing traits.** When you remove a trait, verify which attributes the code under test actually requires. If the service calls `User.visible` and that scope requires `status: "active"`, you must set `status` explicitly — the trait was setting it silently. Read the scope definition before choosing replacement attributes.

**`create_default` only works for top-level factory associations.** `create_default(:user)` sets a thread-local default so that any factory calling `user` (top-level association) reuses the existing record. However, it does NOT intercept associations defined inside traits — if a trait defines `address` which itself has a `user` association, `create_default(:user)` won't prevent the cascade. For trait cascades, eliminate the trait instead.

## Spec Ordering Convention

Within each `describe`/`context` block, declarations follow this order:

1. `subject`
2. `let_it_be` — static data (created once)
3. `let` / `let!` — per-context overrides
4. `before_all` — static setup (no mocks)
5. `before` — per-example setup (mocks, stubs)
6. Examples (`it` / `specify`)
7. Nested `context` blocks

```ruby
RSpec.describe MyService, type: :service do
  subject { described_class.call(user: user, params: params) }

  # 1. Static data (let_it_be)
  let_it_be(:user) { create(:user) }
  let_it_be(:account) { create(:account) }

  # 2. Per-context data (let) — only when overridden below
  let(:params) { { name: "test" } }

  # 3. Static setup (before_all)
  before_all do
    create(:membership, user:, account:, role: "owner")
  end

  # 4. Per-example setup (before) — only for mocks or mutable state
  before do
    allow(ExternalApi::Client).to receive(:call).and_return(success_response)
  end

  # 5. Tests
  it "does the thing" do
    subject
    expect(...).to ...
  end

  context "when condition varies" do
    let(:params) { { name: "" } }  # override is why this uses let

    it "handles the edge case" do ...
  end
end
```

## Critical Rules

### `let_it_be` by default
Use `let_it_be` for all static data (see Quick Reference above). This is the single biggest speed win — heavy specs often drop from hundreds of factory creates to a handful.

### `before_all` for static setup
If a `before` block only creates records or sets up static state (no mocks), use `before_all`.

### Scope expensive operations narrowly
Materialized view refreshes, search index reindexing, external data syncs, file generation — scope these to only the contexts that need them. Don't pay the cost for every example.

### Don't over-create records
To test a `MAX_LIMIT` cap, create `MAX_LIMIT + 1` records, not 600. Extract math into a testable unit and test with plain numbers when possible.

### Make retry delays configurable
If the service under test has retry logic with `sleep`, make the delay configurable and pass `retry_delay: 0` (or `0.01`) in specs. Never let specs sleep for real.

### One canonical spec per shared resolver / action
When two endpoints share a resolver or controller action (e.g., a public and an admin GraphQL type both expose `#summary`), test the logic fully in one spec. The other gets a single smoke test with a comment pointing to the canonical spec.

### Handler specs (GraphQL / controller): mock services, don't retest logic

```ruby
# WRONG -- 9 contexts testing eligibility logic through full GraphQL/HTTP execution
describe "#can_perform_action" do
  context "when already performed" do ... end   # business logic
  context "when owner" do ... end                # business logic
  # 7 more contexts...
end

# RIGHT -- handler spec delegates, service spec has full coverage
describe "#can_perform_action" do
  let(:service_result) { { allowed: true } }

  before { allow(EligibilityService).to receive(:call).and_return(service_result) }

  it "delegates to the service" do
    subject
    expect(EligibilityService).to have_received(:call).with(
      user: current_user, resource: resource
    )
  end

  it "returns the service result" do
    expect(result.dig("canPerformAction")).to eq("allowed" => true)
  end
end
```

NEVER add more contexts to a handler spec for delegated logic — if you need to test different service inputs/outputs, those tests belong in the service spec.

## Red Flags

### `let_it_be` / `before_all` safety

| Pattern | Why | Fix |
|---------|-----|-----|
| `let(:x) { create(...) }` for static data | N examples = N unnecessary DB writes | `let_it_be` (check pre-conversion checklist above) |
| `before { create(...) }` for static setup | Same — runs per example | `before_all` |
| `let_it_be` redefined in nested context | Evaluated once at load time — redefining is fragile and may not override as expected | Use `let` for values that vary per context |
| `let_it_be(:x)` where a dependency is overridden via `let` in nested contexts | Record was created with the ORIGINAL dependency — nested overrides are invisible, causing silent wrong-data bugs | Keep the entire dependency chain as `let` |
| `let_it_be` object referenced by nested `create` with a unique constraint | Shared object persists across contexts; nested creates hit duplicate-entry errors on the unique index | Use `let` for the parent object in those contexts |
| Top-level `let!` → `let_it_be` when nested contexts redefine the same name with different associations | The `let_it_be` record persists in DB and is still associated with shared parents; nested `let(:name)` shadows the Ruby variable but the DB record is still there, polluting queries that count or filter by association | Keep as `let!` when the name is redefined in nested contexts AND the record is associated with a shared parent |
| `before_all` or `let_it_be` factory that writes to Redis/cache | DB transaction savepoints don't roll back cache — later examples see stale state | Use `before`/`let`, or add explicit cache cleanup in `after` |
| `before_all` creating records that reference data overridden in sibling contexts | `before_all` records persist across sibling contexts; if a sibling overrides a dependency, the `before_all` records still reference the original — causing wrong counts or wrong associations (see example below) | Keep as `before` when sibling contexts override any data used in the setup |
| `let_it_be(:record)` without `refind: true` when sibling contexts load associations on the same object | Association cache persists on the Ruby object even after DB records are rolled back — next context gets stale cached data instead of querying DB | Use `let_it_be(:record, refind: true)` to get a fresh Ruby object per example |
| `before_all` / `let_it_be` factory on a model with `before_commit`/`after_commit` callbacks that create OTHER records | Callback-created records are committed outside the savepoint — they persist across examples and cause `RecordNotUnique` when a nested `let_it_be` tries to create the same record | Find the callback-created record instead of creating a duplicate: `Model.find_by!(...).tap { \|m\| m.update_columns(...) }` |
| `travel_to` or `freeze_time` inside `before_all` | Time stays frozen across all examples and leaks to other spec files | Use `before { travel_to(...) }` or block form |

**`before_all` sibling leak example:**

```ruby
# WRONG — before_all records leak into sibling context that overrides the parent
context "when filtering posts" do
  let_it_be(:user) { create(:user, :active) }

  before_all do
    create_list(:post, 2, user: user)  # created with :active user
  end

  it "returns 2 posts" do ... end  # passes

  context "when user is suspended" do
    let(:user) { create(:user, :suspended) }
    # before_all posts still point to the ORIGINAL :active user!
    it "returns 0 posts for suspended user" do ... end  # FAILS
  end
end

# RIGHT — keep as `before` so each context gets its own records
  before do
    create_list(:post, 2, user: user)
  end
```

### Layer & coverage

| Pattern | Why | Fix |
|---------|-----|-----|
| Business logic tested through GraphQL/HTTP | Slow, brittle, duplicates service coverage | Mock service in handler spec, test logic in service spec |
| >3 `create` calls to set up a single handler spec context | Handler has business logic that belongs in a service | Extract to service, mock in handler spec |
| `sidekiq: :inline` (or equivalent) in service spec | Exercises 4+ layers in one test, blocks CI queue | Test each layer independently |
| Testing privates via `send` | Signals class should be decomposed | Extract to smaller public objects |
| Shared example generating >5 contexts | Test concern at a lower layer instead | Extract and test independently |
| `skip_callbacks` or `update_columns` in test setup | Fighting the framework to work around side effects | Extract logic to a service/model that doesn't trigger callbacks |

### Factory & mock hygiene

| Pattern | Why | Fix |
|---------|-----|-----|
| `create_list` with count >50 | Over-population for boundary test | Use threshold + 1, or test math separately |
| `FactoryBot.create` inside `subject` or `it` block | Hides setup, breaks `let_it_be` benefits | Move to `let_it_be` / `let` / `before_all` |
| Factory `total` count far exceeds `top-level` count | Factory cascade — implicit associations creating redundant records | Inline associations in factory definitions or share via `let_it_be` |
| Trait used only for its attribute defaults, not its associations | Trait associations cascade silently — often the #1 factory waste source | Replace trait with explicit attributes; check model scopes to know which attributes are required |
| Optional associations defined in factory default | Every `create` pays for associations the test doesn't need | Remove from factory; add explicitly in tests that need them |
| `allow_any_instance_of(Klass)` | Fragile, unclear which instance is stubbed | Inject dependency or stub on the specific object |
| Mocking internal code | Over-mocking hides real bugs; only external APIs need isolation | Mock external HTTP calls (WebMock); let internal code run |

### General

| Pattern | Why | Fix |
|---------|-----|-----|
| Spec file >1,000 lines | Skews CI queue — one worker stuck while others idle | Split by domain |
| `sleep` in specs | Wastes real seconds on retry backoff | Pass `retry_delay: 0`, or extract retry to infrastructure |
| `before` block with >5 stubs | Service has too many responsibilities | Decompose service |
| `rubocop:disable Rails/Output` | Specs must be automated, not human-verified | Remove debug output |

## Escalation Ladders

### Data setup isn't working

`let_it_be` → `let_it_be(refind: true)` → `let` → `before { create(...) }` (last resort)

**Conversion broke tests? Diagnose by symptom:**

| Symptom | Cause | Fix |
|---------|-------|-----|
| `RecordNotUnique` / duplicate entry | Model callback (`before_commit`, `after_commit`) implicitly creates records that survive the savepoint | Find the callback-created record instead of creating a duplicate: `Model.find_by!(...).tap { \|m\| m.update_columns(...) }` |
| Stale data / wrong attribute values | Same Ruby object reused across examples; mutations or association cache persist | Add `refind: true` to get a fresh object per example |
| Wrong associations / unexpected counts | Dependency in the chain is overridden in nested contexts but `let_it_be` record was created with original | Keep entire dependency chain as `let` |
| `leaked into another example` error | Mocks or doubles used inside `let_it_be` / `before_all` | Move mocks to `before`, keep `let_it_be` for DB records only |
| Unique constraint in nested context | Nested `create` conflicts with persistent `let_it_be` record on same unique index | Use `let` for the parent object in those contexts |

### Logic is at the wrong layer but can't extract now

1. Write minimal handler spec + `# TODO: extract to service — logic doesn't belong here`
2. Don't add more wrong-layer tests on top
3. When you next touch this code, extract first

### Flaky or slow spec

Inline diagnostic steps (no external docs required):

1. **Reproduce ordering issues**: `bundle exec rspec --seed <seed> --bisect` to isolate the minimal failing pair.
2. **Profile factory usage** (test-prof): `FPROF=1 bundle exec rspec spec/path/to/file.rb` to see top-level vs total factory counts. A large gap = cascade. `EVENT_PROF='sql.active_record' bundle exec rspec` to surface SQL hotspots.
3. **Find slow examples**: `--profile 10` prints the slowest 10.
4. **Time-leak suspect?** Search for `travel_to` / `freeze_time` inside `before_all` / `let_it_be` blocks.
5. **State-leak suspect?** Check for Redis/cache writes, `update_columns`, or model callbacks that bypass the transaction.
6. **Mock-leak suspect?** `leaked into another example` errors mean a mock was set up in `before_all` or `let_it_be` — move it to `before`.

## Suite-level speed (CI)

`let_it_be`/factory tuning is per-example. These four levers cut whole-suite CI
time and are usually cheaper per second saved. Do them roughly in this order —
the first is almost free and often the biggest.

### 1. Quiet the logs (do this first)

The default test `log_level` is `:debug`, so every SQL statement is written to
`log/test.log` — a suite emitting tens of thousands of queries pays real I/O for
output nobody reads. In `config/environments/test.rb`:

```ruby
config.log_level = :fatal
config.active_record.verbose_query_logs = false     # no per-query backtrace
config.active_record.query_log_tags_enabled = false  # no SQL comment tagging
```

Usually the biggest cheap win in a suite that has never been tuned: in Evil
Martians' write-up, quieting the verbose query logs together with a Sentry
logger fix took a single-process run from ~25min to ~12min, with the query
logging doing the heavy lifting. Costs nothing and never changes behavior.

### 2. Weaken expensive global setup in test

Cryptographic KDFs (Argon2id, bcrypt, scrypt, PBKDF2), blind indexes, and
password hashing are CPU bottlenecks that dominate the *slowest examples* —
they're designed to be slow. Use minimal cost in test only:

```ruby
# bcrypt
BCrypt::Engine.cost = BCrypt::Engine::MIN_COST   # in test setup
# Argon2 / custom KDF — expose t_cost/m_cost/p_cost as env-aware config and
# use the cheapest params in test (e.g. t_cost: 1, tiny m_cost).
```

Find them: they're the top entries in `--profile`. If your slowest specs are all
one crypto/auth feature, this is the fix, not factory work.

### 3. Parallelize fairly (runner choice matters)

Running across CPU cores is the biggest wall-clock lever once the above are done,
but the runner matters:

- **`parallel_tests`** splits *files* across processes up front (static). The
  slowest file becomes the bottleneck and each worker boots the app separately.
- **`test-queue`** (preferred) forks workers after one boot and hands out
  examples from a shared queue — a free worker grabs the next spec, so slow
  files can't strand a worker, and there's no per-worker re-boot. This is what
  Rails' own Minitest `parallelize` does (fork + distribute), which is why a
  Minitest suite often looks "faster" than a single-process RSpec — it's the
  parallelism, not the framework.

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

On CI, know your core count first (GitHub-hosted **private** repos get 2 vCPUs,
public get 4) — cache the runtime log for runtime-based balancing.

**A fair queue exposes every latent isolation bug** — specs that only passed
because another file ran first in the same process. This is a feature: it finds
real order-dependence. When a spec fails only under parallelism, run it *alone*
(`rspec path/to/x_spec.rb`) — if it fails there too, it's a self-sufficiency bug
(a missing `require`/constant, or leaked global state), not the runner.

### 4. Global failsafes for leaky state

Under a fair runner, one leaked global crashes unrelated specs in other workers.
Add belt-and-suspenders resets in `spec/rails_helper.rb`:

```ruby
config.after { travel_back }  # undo any stray travel_to/freeze_time
# reset any singletons / global clients / thread-locals the app sets
```

Clearing the cache needs care under parallelism: with a shared store, one
worker's `Rails.cache.clear` wipes every other worker's entries. Namespace the
store per worker first, then clear.

Only if the app uses `:redis_cache_store` (or any shared store) in test:

```ruby
# config/environments/test.rb
config.cache_store = :redis_cache_store,
  { namespace: "test#{ENV.fetch("TEST_ENV_NUMBER", "")}" }

# spec/rails_helper.rb
config.after { Rails.cache.clear }
```

Under `test-queue` nothing sets `TEST_ENV_NUMBER` — assign it in the custom
runner's `after_fork` (`ENV["TEST_ENV_NUMBER"] = num.to_s`) so the same
namespacing works there.

Otherwise (`:null_store`/`:memory_store`, i.e. per-process) just:

```ruby
# spec/rails_helper.rb
config.after { Rails.cache.clear }
```

Prefer fixing the leak at its source (the time-leak / mock-leak red flags
above); the global `after` is the safety net for what slips through.

## Profiler cheat-sheet

| Env / flag | Tool | Answers |
|---|---|---|
| `FPROF=1` | FactoryProf | per-factory create counts; `total` ≫ `top-level` = cascade |
| `FACTORY_DEFAULT_PROF=1` | FactoryDefault prof | which implicit associations `create_default` could share |
| `EVENT_PROF='sql.active_record'` | EventProf | time spent in SQL (is it even the bottleneck?) |
| `EVENT_PROF='factory.create'` | EventProf | share of time in factories |
| `RD_PROF=1` | RSpecDissect | `before`-hook time vs example-body time, slowest groups |
| `TPS_PROF=1` | TPS profiler | files with the most shared-setup overhead per example (best `let_it_be` candidates) |
| `TEST_MEM_PROF=gc` | Memory profiler | examples contributing most to GC time |
| `TEST_STACK_PROF=1` | StackProf | CPU flamegraph of the hottest code paths |
| `--profile 10` | RSpec | slowest 10 examples |
| `--seed N --bisect` | RSpec | minimal failing example pair for an order-dependence |

Start with `EVENT_PROF`/`FPROF` to confirm *where* time goes before optimizing —
if SQL is ~10% and factories are a third, don't chase N+1s.

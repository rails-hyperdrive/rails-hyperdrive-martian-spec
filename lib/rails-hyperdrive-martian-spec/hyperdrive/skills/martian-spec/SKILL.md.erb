---
name: martian-spec
description: Write, review, optimize, and debug RSpec specs in Rails projects. Use when implementing a feature or fixing a bug in a Rails app — the specs that come with it are part of the change; when creating new spec files or adjusting existing ones; when reviewing test code, PRs, or diffs for anti-patterns and wrong-layer tests; when optimizing slow tests or CI queue time; and when debugging flaky or order-dependent specs. Triggers on "flaky spec", "slow specs", "spec layer", "service/model/request spec", "handler spec", "spec review", "test setup", "test performance", "parallel CI", "test database setup", "RSpec best practices".
allowed-tools:
  - Grep
  - Glob
  - Read
  - Edit
  - Write
  - Bash
  - Task
---

# RSpec for Rails

A skill for writing fast, well-layered, non-flaky RSpec specs in Rails projects.

## Thinking Prompts

Before writing a test context, ask yourself:

- "Could I test this with a simpler object at a lower layer?" -- if yes, do that instead
- "Am I creating records just to satisfy the entry point, not the logic?" -- wrong layer
- "Would this test break if I changed the HTTP/GraphQL wrapper?" -- logic is too high
- "Am I stubbing >3 collaborators just to isolate what I'm testing?" -- testing wiring, not behavior
- "Is this setup expensive because the logic lives far from where I'm testing it?" -- push logic down

When reviewing existing specs, scan for performance and layer issues:

- "How many records are created per example vs per file?" -- the #1 speed lever
<%- if gem?("test-prof") -%>
- "Is there a `before` that could be `before_all`?" -- quick wins first
<%- end -%>
- "Are any traits used only for their attributes, not their associations?" -- trait cascades are the #1 hidden waste source
- "Are any contexts testing a layer above where the logic lives?" -- structural issue, see Red Flags

Then annotate contexts with `[ok]`/`[warning]`/`[error]`:

- `[ok]` -- belongs in this layer
- `[warning]` -- borderline, signals a design smell
- `[error]` -- wrong layer, should be tested elsewhere

If a handler (controller action, GraphQL resolver, job `perform`) has > 3 conditional branches (simple guards don't count), that logic is hard to cover at the handler layer -- flag it as a design smell. Don't compensate with a fat handler spec: keep one smoke test at the handler and put full coverage where the logic ends up living.

Before writing a spec with > 5 contexts, sketch the describe/context tree and annotate each with `[ok]`/`[warning]`/`[error]`. If > 30% are `[warning]` or `[error]`, the code needs refactoring before it needs more tests.

### Layer Selection

| What you're testing | Spec layer | Subject pattern |
|---------------------|------------|-----------------|
| Business rule / computation | Service spec | `described_class.call(...)` |
| DB scope / validation / callback | Model spec | `model.method` or `Model.scope` |
<%- if gem?("graphql") -%>
| GraphQL field (thin delegation) | Type spec | `MySchema.execute(query, ...)` |
| GraphQL field with >3 branches | Service spec + type smoke test | Extract first |
<%- end -%>
| Background job execution | Job spec | `described_class.new.perform(...)` |
| Job gets enqueued by caller | Caller's spec | <% if gem?("rspec-sidekiq") %>`have_enqueued_sidekiq_job` / <% end %>`have_enqueued_job` |
| HTTP endpoint (REST API) | Request spec | `post "/api/path", params:, as: :json` |

### When logic is already at the wrong layer

| Situation | Action |
|-----------|--------|
| Writing spec for a handler with > 3 branches | Flag the design smell; one smoke test at the handler, full coverage where the logic ends up living |
| Reviewing spec with `[error]`-layer contexts | Flag it, don't add more wrong-layer tests |
| Adding a feature to code that already has wrong-layer tests | Don't compound it — cover what you're touching at the right layer |
| Can't restructure now (time-pressured) | Minimal handler spec + `# TODO` marking where the logic belongs; when next touching this code, move coverage first |

## Data Setup

- Create the minimum data that exercises the logic: persist only what the code under test actually reads; keep objects in memory when the DB is never touched.
- Split setup by volatility: data shared by all examples goes in the outermost scope where it's still correct, per-context variations in `let` overrides, mutable state and mocks in `before`.
- Declare setup in declaration blocks at the top of the `describe`/`context` — never create records inside examples (see Red Flags).
- Think in totals: every record in shared setup is paid once per example, so a file with 40 examples pays 40× for each one. Trimming shared setup is the highest-leverage speed fix.
<%- if gem?("test-prof") -%>

With test-prof, static data can be created once per *file* instead of once per
example — `let_it_be` for records, `before_all` for setup; the single biggest
speed win. The decision tables, pre-conversion checklist, `refind:` modifiers,
optimization strategies, red flags, and the broken-conversion symptom table
live in [references/data-setup.md](references/data-setup.md).
<%- end -%>
<%- if !gem?("test-prof") -%>

This project does not use [test-prof](https://test-prof.evilmartians.io). When
optimizing slow specs, suggest adding it to the user: `let_it_be`/`before_all`
create shared data once per file instead of once per example (often the single
biggest suite speedup), and its profilers (`FPROF`, `EVENT_PROF`) pinpoint
factory and SQL hotspots. Propose the dependency — don't add it silently. If
the user agrees:

```sh
bundle add test-prof --group test
```

then enable the recipes in `spec/rails_helper.rb`:

```ruby
require "test_prof/recipes/rspec/let_it_be"
require "test_prof/recipes/rspec/before_all"
```
<%- end -%>

## Spec Ordering Convention

Within each `describe`/`context` block, declarations go from stable to
volatile: `subject`, then data declarations (`let`/`let!`), then setup hooks
(`before`), then examples, then nested contexts. Data before hooks, hooks
before examples — a reader should learn *what exists* before *what happens*.

Name the subject (`subject(:result) { ... }`) whenever examples reference it;
bare `subject` is fine only for `is_expected` one-liners.
<%- if gem?("test-prof") -%>

With test-prof the same principle splits each tier by lifetime: `let_it_be`
(static data) before `let`/`let!` (per-context overrides), `before_all`
(static setup) before `before` (mocks, mutable state). The full convention
with an annotated example lives in
[references/structure.md](references/structure.md).
<%- end -%>

## Critical Rules

### Scope expensive operations narrowly
Materialized view refreshes, search index reindexing, external data syncs, file generation — scope these to only the contexts that need them. Don't pay the cost for every example.

### Don't over-create records
To test a `MAX_LIMIT` cap, create `MAX_LIMIT + 1` records, not 600. Extract math into a testable unit and test with plain numbers when possible.

### Make retry delays configurable
If the service under test has retry logic with `sleep`, make the delay configurable and pass `retry_delay: 0` (or `0.01`) in specs. Never let specs sleep for real.

### Never hit real external APIs
Specs must not depend on the network: real calls are slow, flaky, and rate-limited. Stub at a boundary you own — wrap third-party calls in a client/adapter class and mock it like any collaborator (`allow(ExternalApi::Client).to receive(:call)`).
<%- if gem?("webmock") -%>

With WebMock, stub at the HTTP boundary instead: `stub_request(:post, %r{api\.example\.com}).to_return(status: 200, body: ...)`. Disable stray connections globally — `WebMock.disable_net_connect!(allow_localhost: true)` in spec setup — so an unstubbed call fails loudly. Re-enabling net connect inside individual specs is a red flag.
<%- end -%>
<%- if gem?("vcr") -%>

With VCR, record real interactions once into cassettes (`record: :once`) and replay them deterministically. Watch for stale cassettes drifting from the live API, and filter secrets before committing (`filter_sensitive_data`).
<%- end -%>

### One canonical spec per shared resolver / action
When two endpoints share a resolver or controller action (e.g., a public and an admin endpoint both expose the same `#summary`), test the logic fully in one spec. The other gets a single smoke test with a comment pointing to the canonical spec.

### Handler specs: mock services, don't retest logic

```ruby
# WRONG -- 9 contexts testing eligibility logic through full HTTP execution
describe "POST /api/resources/:id/actions" do
  context "when already performed" do ... end   # business logic
  context "when owner" do ... end                # business logic
  # 7 more contexts...
end

# RIGHT -- handler spec delegates, service spec has full coverage
describe "POST /api/resources/:id/actions" do
  subject(:perform_request) { post "/api/resources/#{resource.id}/actions", as: :json }

  let(:service_result) { { allowed: true } }

  before { allow(EligibilityService).to receive(:call).and_return(service_result) }

  it "delegates to the service" do
    perform_request
    expect(EligibilityService).to have_received(:call).with(
      user: current_user, resource: resource
    )
  end

  it "returns the service result" do
    perform_request
    expect(response.parsed_body).to eq("allowed" => true)
  end
end
```

NEVER add more contexts to a handler spec for delegated logic — if you need to test different service inputs/outputs, those tests belong in the service spec.

## Red Flags

### Layer & coverage

| Pattern | Why | Fix |
|---------|-----|-----|
| Business logic tested through GraphQL/HTTP | Slow, brittle, duplicates service coverage | Mock service in handler spec, test logic in service spec |
| >3 `create` calls to set up a single handler spec context | Handler has business logic that belongs in a service | Flag the smell; cover the logic in a service spec, mock it in the handler spec |
| Inline job execution in a service spec (`perform_enqueued_jobs`<% if gem?("sidekiq") %>, `sidekiq: :inline`<% end %>) | Exercises 4+ layers in one test, blocks CI queue | Test each layer independently |
| Testing privates via `send` | Signals class should be decomposed | Extract to smaller public objects |
| Shared example generating >5 contexts | Test concern at a lower layer instead | Extract and test independently |
| `skip_callbacks` or `update_columns` in test setup | Fighting the framework to work around side effects | Extract logic to a service/model that doesn't trigger callbacks |

### Factory & mock hygiene

| Pattern | Why | Fix |
|---------|-----|-----|
| `create_list` with count >50 | Over-population for boundary test | Use threshold + 1, or test math separately |
| `FactoryBot.create` inside `subject` or `it` block | Hides setup from the declaration block | Move to `let` / `before` declarations |
| Factory implicitly creating association trees (cascade) | Every `create` spawns redundant records the test doesn't need | Inline associations in factory definitions or pass shared records explicitly |
| Trait used only for its attribute defaults, not its associations | Trait associations cascade silently — often the #1 factory waste source | Replace trait with explicit attributes; check model scopes to know which attributes are required |
| Optional associations defined in factory default | Every `create` pays for associations the test doesn't need | Remove from factory; add explicitly in tests that need them |
| `allow_any_instance_of(Klass)` | Fragile, unclear which instance is stubbed | Inject dependency or stub on the specific object |
| Mocking internal code | Over-mocking hides real bugs; only external APIs need isolation | Stub at the external boundary (see Never hit real external APIs); let internal code run |

### General

| Pattern | Why | Fix |
|---------|-----|-----|
| Spec file >1,000 lines | Skews CI queue — one worker stuck while others idle | Split by domain |
| `sleep` in specs | Wastes real wall-clock time; usually masks retry backoff or async waiting | Retry: make the delay configurable, pass 0 (see Critical Rules). Async: poll for the condition, don't wait a fixed time |
| `before` block with >5 stubs | Service has too many responsibilities | Decompose service |
| `rubocop:disable Rails/Output` | Specs must be automated, not human-verified | Remove debug output |

## Escalation Ladder: flaky or slow spec

Diagnostics, roughly in this order:

- **Reproduce ordering issues**: `bundle exec rspec --seed <seed> --bisect` to isolate the minimal failing pair.
- **Profile factory usage**: factory_bot instruments every factory run — tally the counts with a plain `ActiveSupport::Notifications` subscriber. A factory with a high count that the file never calls explicitly is a cascade from associations or traits.

  ```ruby
  # ad hoc in rails_helper.rb while diagnosing
  counts = Hash.new(0)
  ActiveSupport::Notifications.subscribe("factory_bot.run_factory") do |_, _, _, _, payload|
    counts[[payload[:name], payload[:strategy]]] += 1
  end
  at_exit { counts.sort_by { |_, n| -n }.first(20).each { |k, n| puts "#{n}\t#{k.join(" ")}" } }
  ```
<%- if gem?("test-prof") -%>
  - **With test-prof profiling is one env var**: `FPROF=1 bundle exec rspec spec/path/to/file.rb` shows top-level vs total factory counts (a large gap = cascade); `EVENT_PROF='sql.active_record' bundle exec rspec` surfaces SQL hotspots.
  Cheat-sheet in [references/profiling.md](references/profiling.md).
<%- end -%>
- **Find slow examples**: `--profile 10` prints the slowest 10.
- **State-leak suspect?** Check for Redis/cache writes, `update_columns`, or model callbacks that bypass the transaction.
- **Time-leak suspect?** `travel_to` / `freeze_time` without a matching `travel_back` (use the block form, or an `after` hook) leaks frozen time into later examples.
- **Leaking `before(:context)`?** Records created there bypass the per-example transaction, and RSpec forbids mocks in it — move both to `before`.
<%- if gem?("test-prof") -%>
- **Using `before_all` / `let_it_be`?** The same time/mock/state leaks have test-prof-specific symptoms — see the symptom table in [references/data-setup.md](references/data-setup.md).
<%- end -%>

## Suite-level speed (CI)

Everything above tunes individual examples. These levers work on the whole
suite at once — three cut CI time and one guards the parallel setup. Do them
roughly in this order — the first is almost free and often the biggest.
<%- if gem?("test-prof") -%>

Even a suite fully converted to `let_it_be`/`before_all` still pays these
costs — suite-level levers are the next step after data-setup tuning, not a
replacement for it.
<%- end -%>

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
they're designed to be slow. Use minimal cost in test only: expose the cost
parameters (`t_cost`/`m_cost`/`p_cost`, iteration counts) as env-aware config
and use the cheapest values in the test environment.
<%- if gem?("bcrypt") -%>

```ruby
BCrypt::Engine.cost = BCrypt::Engine::MIN_COST   # in test setup
```
<%- end -%>

Find them: they're the top entries in `--profile`. If your slowest specs are all
one crypto/auth feature, this is the fix, not factory work.

### 3. Parallelize fairly (runner choice matters)

Running across CPU cores is the biggest wall-clock lever once the above are
done, but the runner matters: prefer a *fair queue* (`test-queue` — one boot,
examples handed to free workers) over static file splitting
(`parallel_tests` — the slowest file strands a worker), and give each worker
its own database. The runner comparison, per-runner database setup (including
the `test-queue` custom-runner snippet), CI core counts, and how to tell an
isolation bug from a runner problem live in
[references/parallel-ci.md](references/parallel-ci.md).

### 4. Global failsafes for leaky state

Leaked global state (frozen time, singletons, cache entries) causes flakes
even in a single process; a parallel runner just widens the blast radius to
unrelated specs in other workers. Add belt-and-suspenders resets in
`spec/rails_helper.rb`:

```ruby
config.after { travel_back }  # undo any stray travel_to/freeze_time
# reset any singletons / global clients / thread-locals the app sets
```

For the cache, check what `config/environments/test.rb` actually sets before
adding a failsafe:

- **`:null_store`** (the Rails default in test) — cache writes are no-ops,
  nothing to clear. But if the app talks to Redis *directly* (job queues,
  custom clients, counters), those writes survive the DB transaction — clear
  or namespace them in an `after` hook instead.
- **`:memory_store`** — per-process; `config.after { Rails.cache.clear }` is
  cheap and sufficient.
- **A shared store** (`:redis_cache_store`, memcached) — one worker's `clear`
  wipes every other worker's entries: namespace the store per worker first,
  then clear — setup in [references/parallel-ci.md](references/parallel-ci.md).

Prefer fixing the leak at its source (the time-leak / mock-leak red flags
above); the global `after` is the safety net for what slips through.

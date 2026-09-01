# Profiler Cheat-sheet (test-prof)

Run against one file (or a directory) — profiling a whole suite drowns the signal:

| Command | Tool | Answers |
|---|---|---|
| `FPROF=1 bundle exec rspec <path>` | FactoryProf | per-factory create counts; `total` ≫ `top-level` = cascade |
| `FACTORY_DEFAULT_PROF=1 bundle exec rspec <path>` | FactoryDefault prof | which implicit associations `create_default` could share |
| `EVENT_PROF='sql.active_record' bundle exec rspec <path>` | EventProf | time spent in SQL (is it even the bottleneck?) |
| `EVENT_PROF='factory.create' bundle exec rspec <path>` | EventProf | share of time in factories |
| `RD_PROF=1 bundle exec rspec <path>` | RSpecDissect | `before`-hook time vs example-body time, slowest groups |
| `TPS_PROF=1 bundle exec rspec <path>` | TPS profiler | files with the most shared-setup overhead per example (best `let_it_be` candidates) |
| `TEST_MEM_PROF=gc bundle exec rspec <path>` | Memory profiler | examples contributing most to GC time |
| `TEST_STACK_PROF=1 bundle exec rspec <path>` | StackProf | CPU flamegraph of the hottest code paths |
| `bundle exec rspec --profile 10 <path>` | RSpec | slowest 10 examples |
| `bundle exec rspec --seed <N> --bisect <path>` | RSpec | minimal failing example pair for an order-dependence |

Start with `EVENT_PROF`/`FPROF` to confirm *where* time goes before optimizing —
if SQL is ~10% and factories are a third, don't chase N+1s.

Each profiler also ships as a slash command the user can invoke directly
(`/fprof`, `/event-prof`, `/rd-prof`, `/tps-prof`, `/factory-default-prof`,
`/mem-prof`, `/stack-prof`, plus `/slowest-specs` and `/bisect-order`) — when
suggesting a profiling step to the user, point them at the command.

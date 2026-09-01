# Profiler Cheat-sheet (test-prof)

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

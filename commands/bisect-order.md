---
description: Isolate the minimal failing example pair for an order-dependent spec
argument-hint: <seed> [spec file or directory]
---

Reproduce and minimize an order-dependence with RSpec's bisect (the seed comes
from the failing CI/local run's output — ask for it if missing):

```sh
bundle exec rspec --seed $ARGUMENTS --bisect
```

Interpret: bisect prints the minimal set of examples that must run together to
reproduce the failure. The *earlier* example in the pair leaks state (time,
mocks, DB records outside the transaction, Redis/cache); the later one is the
victim. Check the leak diagnostics in the `martian-spec` skill's Escalation
Ladder to classify and fix it.

Example: `/bisect-order 54321 spec/models/`

Report the minimal failing pair, the leaked state, and the fix.

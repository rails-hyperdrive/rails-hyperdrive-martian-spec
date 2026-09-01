---
description: Count factory runs per factory (test-prof FactoryProf) to find cascades
argument-hint: <spec file or directory>
---

Run test-prof's FactoryProf against the given path (ask for one if missing —
whole-suite runs drown the signal):

```sh
FPROF=1 bundle exec rspec $ARGUMENTS
```

Interpret the table: `top-level` is factories the specs called explicitly,
`total` includes records spawned through associations and traits. `total` ≫
`top-level` for a factory means a cascade — trace the gap to an association or
trait and inline or share it (see the `martian-spec` skill's
`references/data-setup.md`).

Example: `/fprof spec/services/billing/`

Report the top offending factories, the cascade source for each, and the fix.

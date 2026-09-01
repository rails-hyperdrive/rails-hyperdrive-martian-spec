---
description: Find files with the most shared-setup overhead per example (best let_it_be candidates)
argument-hint: <spec directory>
---

Run test-prof's TPS profiler against the given directory (ask for one if
missing):

```sh
TPS_PROF=1 bundle exec rspec $ARGUMENTS
```

Interpret: files at the top pay the most repeated setup per example — they are
the best `let_it_be`/`before_all` conversion candidates, where one conversion
saves the most total time. Verify each against the pre-conversion checklist in
the `martian-spec` skill's `references/data-setup.md` before converting.

Example: `/tps-prof spec/services/`

Report the top files and the estimated win for converting each.

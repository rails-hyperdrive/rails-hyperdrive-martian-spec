---
description: Print the slowest examples and groups in a spec run
argument-hint: <spec file or directory>
---

Run RSpec's built-in profiler against the given path (or the whole suite —
this one is cheap enough):

```sh
bundle exec rspec --profile 10 $ARGUMENTS
```

Interpret: this says *which* examples are slow, not *why*. If the top entries
cluster around one feature (e.g. everything touches password hashing), suspect
expensive global setup. Follow up with the profiling steps in the
`martian-spec` skill's Escalation Ladder to find the cause.

Example: `/slowest-specs spec/`

Report the slowest examples and the pattern they share, if any.

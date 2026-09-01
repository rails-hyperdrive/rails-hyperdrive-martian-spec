---
description: CPU flamegraph of the hottest code paths in a spec run (test-prof + stackprof)
argument-hint: <spec file or directory>
---

Run test-prof's StackProf integration against the given path (ask for one if
missing; requires the `stackprof` gem):

```sh
TEST_STACK_PROF=1 bundle exec rspec $ARGUMENTS
```

Then inspect the generated dump (path is printed at the end of the run):

```sh
bundle exec stackprof tmp/test_prof/stack-prof-report-*.dump --text | head -30
```

Interpret: this answers *what code* burns CPU when factories and SQL are
already ruled out — crypto/KDF calls (bcrypt, Argon2) in auth-heavy specs are
the classic finding; weaken their cost in test config, don't optimize specs
around them.

Example: `/stack-prof spec/requests/auth/`

Report the hottest frames and whether the fix is config, code, or specs.

---
description: Split before-hook time from example-body time (test-prof RSpecDissect)
argument-hint: <spec file or directory>
---

Run test-prof's RSpecDissect against the given path (ask for one if missing):

```sh
RD_PROF=1 bundle exec rspec $ARGUMENTS
```

Interpret: heavy `before`-hook time with light example bodies means the setup
should be shared — `let_it_be` for data, `before_all` for setup (check the
pre-conversion checklist in the `martian-spec` skill's
`references/data-setup.md` first). Heavy example bodies point at the code
under test or over-asserting examples, not setup.

Example: `/rd-prof spec/requests/`

Report the hook/body split for the slowest groups and the conversion candidates.

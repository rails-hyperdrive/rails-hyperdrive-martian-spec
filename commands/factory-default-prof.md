---
description: Find implicit associations that create_default could share (test-prof FactoryDefault)
argument-hint: <spec file or directory>
---

Run test-prof's FactoryDefault profiler against the given path (ask for one if
missing):

```sh
FACTORY_DEFAULT_PROF=1 bundle exec rspec $ARGUMENTS
```

Interpret: the report counts how often each factory was created as an implicit
association — high counts are records `create_default` could share instead of
re-creating. Caveat: `create_default` only intercepts top-level factory
associations, not associations defined inside traits — for trait cascades,
eliminate the trait instead (see the `martian-spec` skill's
`references/data-setup.md`).

Example: `/factory-default-prof spec/models/`

Report the top shareable associations and whether `create_default` applies.

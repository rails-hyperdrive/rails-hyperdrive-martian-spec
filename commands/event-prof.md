---
description: Measure time spent in one event type (test-prof EventProf), e.g. SQL or factories
argument-hint: <spec file or directory> [event]
---

Run test-prof's EventProf against the given path (ask for one if missing).
The second argument is the event; default to `sql.active_record`:

```sh
EVENT_PROF='sql.active_record' bundle exec rspec <path>   # time in SQL
EVENT_PROF='factory.create' bundle exec rspec <path>      # time in factories
```

Interpret the share, not the absolute number: if SQL is ~10% of total time,
don't chase N+1s — profile factories and hooks instead. If factories dominate,
follow up with `/fprof` to find which ones.

Examples: `/event-prof spec/models/user_spec.rb`,
`/event-prof spec/services/ factory.create`

Report the event's share of total time and where to look next.

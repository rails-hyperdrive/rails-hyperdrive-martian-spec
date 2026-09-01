---
description: Find examples contributing most to GC time (test-prof memory profiler)
argument-hint: <spec file or directory>
---

Run test-prof's memory profiler against the given path (ask for one if
missing):

```sh
TEST_MEM_PROF=gc bundle exec rspec $ARGUMENTS
```

Interpret: examples at the top allocate the most and drive GC pauses — usual
suspects are giant fixtures/payloads built per example, `create_list` with big
counts, and loading large files in setup. Share or shrink the allocation
rather than tuning GC.

Example: `/mem-prof spec/services/import/`

Report the top allocating examples and what they allocate.

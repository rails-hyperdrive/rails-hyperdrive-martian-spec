# Data Setup (test-prof)

`let_it_be` and `before_all` create data once per spec file instead of once
per example — the single biggest per-example speed win. This reference holds
the decision rules, the safety red flags, and the recovery ladder.

## Critical Rules

### `let_it_be` by default
Use `let_it_be` for all static data (see Quick Reference above). This is the single biggest speed win — heavy specs often drop from hundreds of factory creates to a handful.

### `before_all` for static setup
If a `before` block only creates records or sets up static state (no mocks), use `before_all`.

## Quick Reference

### Use `let_it_be` when:

| Situation | Variant | Why |
|-----------|---------|-----|
| Data never changes between examples | `let_it_be(:x) { create(...) }` | Created once, shared across examples |
| Record mutated by code under test | `let_it_be(:x, refind: true)` | `refind: true` does a full `find` after each example (fresh Ruby object); use `let` if mutation is destructive (soft-delete, discard) |
| Static setup (no mocks involved) | `before_all { create(...) }` | Runs once, not per example |

### Keep as `let` when (NOT `let_it_be`):

| Situation | Why |
|-----------|-----|
| Value overridden in nested contexts | `let_it_be` is frozen at creation; nested `let` overrides won't affect it |
| ANY dependency in the chain is overridden in nested contexts | Transitive: if the root is overridden, every dependent that references it must ALL stay as `let` — `let_it_be` records were created with the original dependency |
| Nested context creates records with unique constraints on a shared object | `let_it_be` reuses the same DB record; a nested `create` hitting a unique index raises `RecordNotUnique` |
| Factory or setup writes to Redis/cache | Transaction savepoints only roll back DB state; cache/Redis writes persist across examples |
| References another `let` that varies | Depends on per-context data that `let_it_be` can't see |
| Setup involves mocks, stubs, or test doubles (`double`, `instance_double`, `spy`) | Mocks and doubles are scoped to one example; `let_it_be` leaks them into subsequent examples causing "leaked into another example" errors |
| Time-sensitive logic | `before_all` / `let_it_be` freezes time across all examples and leaks to other files; use `before { travel_to(time) }` |
| `before` block creates records referencing data that sibling contexts override | `before_all` records persist across ALL sibling contexts; if a sibling redefines a dependency, the `before_all` records still reference the original — keep as `before` |

### Pre-conversion checklist: `let` → `let_it_be`

Before converting, verify ALL of these:
- [ ] No nested `let` override of any dependency in the chain
- [ ] No unique constraints on the shared object in nested contexts
- [ ] No Redis/cache writes in the factory or setup
- [ ] Declaration appears AFTER all its `let_it_be` dependencies in source order
- [ ] No model callbacks (`before_commit`, `after_commit`) on created records that implicitly create other persistent records (these survive savepoint rollback and cause unique constraint violations)
- [ ] For `before` → `before_all`: no sibling context overrides any data the block references (records leak across siblings)

**`let_it_be` modifiers:** Prefer `refind: true` over `reload: true` — `reload: true` is a half-measure that re-reads attributes but keeps the same Ruby object, while `refind: true` does a full `Model.find` returning a completely fresh object. When neither modifier works (soft-delete, `discard`), fall back to `let`.

**`refind: true` side-effect:** `refind` issues a `SELECT *` per example. If the spec asserts on SQL events, filter out the reload query.

### Optimization strategies (don't leave speed on the table)

**Use `refind: true` to unlock cascading conversions.** When a record is mutated in nested contexts (e.g., `user.save!`, `record.update!`) but NOT destroyed, use `let_it_be(:record, refind: true)` instead of falling back to `let`. This lets all dependents also become `let_it_be`, saving dozens of factory calls. Only fall back to `let` when the mutation is destructive (soft-delete, discard).

**Use `refind: true` when sibling contexts load the same association.** Without `refind`, `let_it_be` reuses the same Ruby object across all contexts. If context A's `before` creates child records and the example loads the association (e.g., `user.posts`), the association cache persists on the Ruby object even after the records are rolled back. Context B then gets stale cached data instead of querying the DB. `refind: true` returns a fresh Ruby object per example, with no stale association cache.

```ruby
# BEFORE: user mutated in contexts → entire chain stays `let`
let(:user) { create(:user) }
let!(:post) { create(:post, user: user) }
let!(:comment) { create(:comment, post: post) }
let!(:reaction) { create(:reaction, user: user) }

# AFTER: refind on the root unlocks the whole chain
let_it_be(:user, refind: true) { create(:user) }
let_it_be(:post) { create(:post, user: user) }
let_it_be(:comment) { create(:comment, post: post) }
let_it_be(:reaction) { create(:reaction, user: user) }
```

**Convert nested single-context declarations.** A `let` inside a context with 1-2 examples and no nested overrides is safe to convert to `let_it_be`. Don't skip these — a file with 20 contexts × 2 examples = 40 unnecessary factory calls if you only optimize the top level. Scan every `describe`/`context` block.

**Hoist duplicate `let` declarations.** When multiple sibling contexts define identical `let(:x) { create(...) }`, hoist the declaration to the shared parent scope. If the parent uses `let_it_be`, the hoisted declaration can too — one factory call instead of N.

**Convert pure-Ruby declarations.** `let` blocks that build non-DB objects (anonymous classes, schema definitions, static hashes) are always safe to convert to `let_it_be` — no DB rollback concerns.

**Break factory cascades by passing shared objects.** When a factory implicitly creates associations, each `create` spawns redundant records. Pass existing `let_it_be` objects to short-circuit the cascade.

```ruby
# BEFORE: 3 contexts × create(:post) = 3 users + 3 categories created implicitly
let(:post) { create(:post) }

# AFTER: share the parent objects, pass them explicitly
let_it_be(:user) { create(:user) }
let_it_be(:category) { create(:category) }
let_it_be(:post) { create(:post, user: user, category: category) }
```

**Eliminate expensive traits that the spec doesn't need.** Factory traits with associations are hidden cascade sources — each trait association spawns its own dependency tree. Profile factories (e.g., test-prof's `FPROF=1`) and look for factories where `total` >> `top-level`; trace the gap to a trait, then replace the trait with only the explicit attributes the test actually requires.

```ruby
# BEFORE: :with_full_profile creates address + avatar + preferences,
# each cascading to additional records
create(:user, :with_full_profile)

# AFTER: replace trait with the attributes the code under test actually checks
create(:user, status: "active", role: "admin")
```

**Check model scopes when replacing traits.** When you remove a trait, verify which attributes the code under test actually requires. If the service calls `User.visible` and that scope requires `status: "active"`, you must set `status` explicitly — the trait was setting it silently. Read the scope definition before choosing replacement attributes.

**`create_default` only works for top-level factory associations.** `create_default(:user)` sets a thread-local default so that any factory calling `user` (top-level association) reuses the existing record. However, it does NOT intercept associations defined inside traits — if a trait defines `address` which itself has a `user` association, `create_default(:user)` won't prevent the cascade. For trait cascades, eliminate the trait instead.

## Red Flags

### `let_it_be` / `before_all` safety

| Pattern | Why | Fix |
|---------|-----|-----|
| `let(:x) { create(...) }` for static data | N examples = N unnecessary DB writes | `let_it_be` (check pre-conversion checklist above) |
| `before { create(...) }` for static setup | Same — runs per example | `before_all` |
| `let_it_be` redefined in nested context | Evaluated once at load time — redefining is fragile and may not override as expected | Use `let` for values that vary per context |
| `let_it_be(:x)` where a dependency is overridden via `let` in nested contexts | Record was created with the ORIGINAL dependency — nested overrides are invisible, causing silent wrong-data bugs | Keep the entire dependency chain as `let` |
| `let_it_be` object referenced by nested `create` with a unique constraint | Shared object persists across contexts; nested creates hit duplicate-entry errors on the unique index | Use `let` for the parent object in those contexts |
| Top-level `let!` → `let_it_be` when nested contexts redefine the same name with different associations | The `let_it_be` record persists in DB and is still associated with shared parents; nested `let(:name)` shadows the Ruby variable but the DB record is still there, polluting queries that count or filter by association | Keep as `let!` when the name is redefined in nested contexts AND the record is associated with a shared parent |
| `before_all` or `let_it_be` factory that writes to Redis/cache | DB transaction savepoints don't roll back cache — later examples see stale state | Use `before`/`let`, or add explicit cache cleanup in `after` |
| `before_all` creating records that reference data overridden in sibling contexts | `before_all` records persist across sibling contexts; if a sibling overrides a dependency, the `before_all` records still reference the original — causing wrong counts or wrong associations (see example below) | Keep as `before` when sibling contexts override any data used in the setup |
| `let_it_be(:record)` without `refind: true` when sibling contexts load associations on the same object | Association cache persists on the Ruby object even after DB records are rolled back — next context gets stale cached data instead of querying DB | Use `let_it_be(:record, refind: true)` to get a fresh Ruby object per example |
| `before_all` / `let_it_be` factory on a model with `before_commit`/`after_commit` callbacks that create OTHER records | Callback-created records are committed outside the savepoint — they persist across examples and cause `RecordNotUnique` when a nested `let_it_be` tries to create the same record | Find the callback-created record instead of creating a duplicate: `Model.find_by!(...).tap { \|m\| m.update_columns(...) }` |
| `travel_to` or `freeze_time` inside `before_all` | Time stays frozen across all examples and leaks to other spec files | Use `before { travel_to(...) }` or block form |

**`before_all` sibling leak example:**

```ruby
# WRONG — before_all records leak into sibling context that overrides the parent
context "when filtering posts" do
  let_it_be(:user) { create(:user, :active) }

  before_all do
    create_list(:post, 2, user: user)  # created with :active user
  end

  it "returns 2 posts" do ... end  # passes

  context "when user is suspended" do
    let(:user) { create(:user, :suspended) }
    # before_all posts still point to the ORIGINAL :active user!
    it "returns 0 posts for suspended user" do ... end  # FAILS
  end
end

# RIGHT — keep as `before` so each context gets its own records
  before do
    create_list(:post, 2, user: user)
  end
```

**Mock-leak example:**

```ruby
# WRONG — mock set up in before_all persists past its example,
# raising "leaked into another example" errors
before_all do
  create(:subscription, user: user)
  allow(PaymentGateway).to receive(:charge).and_return(success)
end

# RIGHT — records in before_all, mocks in before
before_all { create(:subscription, user: user) }
before { allow(PaymentGateway).to receive(:charge).and_return(success) }
```

## Escalation Ladder

`let_it_be` → `let_it_be(refind: true)` → `let` → `before { create(...) }` (last resort)

**Conversion broke tests? Diagnose by symptom:**

| Symptom | Cause | Fix |
|---------|-------|-----|
| `RecordNotUnique` / duplicate entry | Model callback (`before_commit`, `after_commit`) implicitly creates records that survive the savepoint | Find the callback-created record instead of creating a duplicate: `Model.find_by!(...).tap { \|m\| m.update_columns(...) }` |
| Stale data / wrong attribute values | Same Ruby object reused across examples; mutations or association cache persist | Add `refind: true` to get a fresh object per example |
| Wrong associations / unexpected counts | Dependency in the chain is overridden in nested contexts but `let_it_be` record was created with original | Keep entire dependency chain as `let` |
| `leaked into another example` error | Mocks or doubles used inside `let_it_be` / `before_all` | Move mocks to `before`, keep `let_it_be` for DB records only |
| Unique constraint in nested context | Nested `create` conflicts with persistent `let_it_be` record on same unique index | Use `let` for the parent object in those contexts |

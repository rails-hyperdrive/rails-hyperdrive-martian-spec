# Spec Ordering Convention (test-prof)

Within each `describe`/`context` block, declarations follow this order:

1. `subject` — named (`subject(:result) { ... }`) whenever examples reference it; bare only for `is_expected` one-liners
2. `let_it_be` — static data (created once)
3. `let` / `let!` — per-context overrides
4. `before_all` — static setup (no mocks)
5. `before` — per-example setup (mocks, stubs)
6. Examples (`it` / `specify`)
7. Nested `context` blocks

```ruby
RSpec.describe MyService, type: :service do
  subject(:result) { described_class.call(user: user, params: params) }

  # 1. Static data (let_it_be)
  let_it_be(:user) { create(:user) }
  let_it_be(:account) { create(:account) }

  # 2. Per-context data (let) — only when overridden below
  let(:params) { { name: "test" } }

  # 3. Static setup (before_all)
  before_all do
    create(:membership, user:, account:, role: "owner")
  end

  # 4. Per-example setup (before) — only for mocks or mutable state
  before do
    allow(ExternalApi::Client).to receive(:call).and_return(success_response)
  end

  # 5. Tests
  it "does the thing" do
    expect(result).to ...
  end

  context "when condition varies" do
    let(:params) { { name: "" } }  # override is why this uses let

    it "handles the edge case" do ...
  end
end
```

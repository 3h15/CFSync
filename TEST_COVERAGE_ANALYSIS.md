# CFSync Test Coverage Analysis

## Executive Summary

CFSync has **13 test files** covering **18 source modules**. While core functionality is well-tested, there are significant gaps in test coverage, particularly around Mix tasks, error handling edge cases, and some rendering features.

---

## Coverage Overview

| Module | Test File | Coverage Level |
|--------|-----------|----------------|
| `lib/cf_sync.ex` | Integration test only | ⚠️ Indirect |
| `lib/cf_sync/entry.ex` | `entry_test.exs` | ✅ Good |
| `lib/cf_sync/asset.ex` | `asset_test.exs` | ✅ Good |
| `lib/cf_sync/link.ex` | `link_test.exs` | ✅ Good |
| `lib/cf_sync/rich_text.ex` | `rich_text_test.exs` | ✅ Good |
| `lib/cf_sync/rich_text_renderer.ex` | `rich_text_renderer_test.exs` | ⚠️ Partial |
| `lib/cf_sync/store.ex` | `store_test.exs` | ✅ Good |
| `lib/cf_sync/store/state.ex` | `store/state_test.exs` | ✅ Good |
| `lib/cf_sync/store/table.ex` | `store/table_test.exs` | ✅ Good |
| `lib/cf_sync/sync_payload.ex` | `sync_payload_test.exs` | ✅ Good |
| `lib/cf_sync/entry/document.ex` | `entry/document_test.exs` | ✅ Good |
| `lib/cf_sync/entry/extractors.ex` | `entry/extractors_test.exs` | ⚠️ Partial |
| `lib/cf_sync/entry/fields.ex` | Behaviour only | N/A |
| `lib/cf_sync/http_client.ex` | Behaviour only | N/A |
| `lib/cf_sync/http_client/httpoison.ex` | `http_client/httpoison_test.exs` | ⚠️ Partial |
| `lib/mix/tasks/cf_sync.dump.ex` | None | ❌ No Coverage |
| `lib/mix/tasks/cf_sync.setup.ex` | None | ❌ No Coverage |
| `lib/mix/tasks/utils.ex` | None | ❌ No Coverage |

---

## Critical Gaps (High Priority)

### 1. Mix Tasks - No Tests At All

**Files affected:**
- `lib/mix/tasks/cf_sync.dump.ex`
- `lib/mix/tasks/cf_sync.setup.ex`
- `lib/mix/tasks/utils.ex`

**Risk:** These tasks interact with the file system and external APIs. Untested code here could lead to data corruption, credential leaks, or silent failures.

**Recommended tests:**

```elixir
# test/mix/tasks/utils_test.exs
defmodule CfSync.Tasks.UtilsTest do
  use ExUnit.Case, async: true

  alias CfSync.Tasks.Utils

  describe "ask/2" do
    test "returns default value when input is empty"
    test "validates input against regex filter"
    test "validates input against list filter"
    test "retries on invalid input"
  end

  describe "read_conf/1 and write_conf!/2" do
    test "round-trips configuration data"
    test "returns :no_file for missing config"
    test "creates directory structure if missing"
  end

  describe "read_dump/1 and write_dump!/2" do
    test "round-trips dump data"
    test "returns :no_file for missing dump"
    test "handles large data files"
  end
end
```

```elixir
# test/mix/tasks/cf_sync.dump_test.exs
defmodule Mix.Tasks.CfSync.DumpTest do
  use ExUnit.Case

  import Mox

  test "exits gracefully when no config exists"
  test "downloads and saves all pages from Contentful"
  test "handles rate limiting during download"
  test "fails after max retry attempts"
end
```

### 2. CFSync Main Module - No Direct Unit Tests

**File:** `lib/cf_sync.ex`

While the integration test covers happy paths, the main module lacks unit tests for:

**Recommended tests:**

```elixir
# test/cf_sync_test.exs (new file for unit tests)
defmodule CFSyncTest do
  use ExUnit.Case, async: true

  describe "get_link_target/1" do
    test "returns nil for non-Link input"
    test "returns nil for nil input"
    test "returns nil when link target doesn't exist"
  end

  describe "get_child/2" do
    test "raises KeyError for missing field"
    test "returns nil when child entry doesn't exist"
  end

  describe "get_children/2" do
    test "filters out nil entries from result"
    test "raises KeyError for missing field"
    test "returns empty list when all children are missing"
  end
end
```

---

## Medium Priority Gaps

### 3. RichTextRenderer - Missing Mark Tests

**File:** `lib/cf_sync/rich_text_renderer.ex`

**Missing coverage for:**
- `superscript/1` mark rendering
- `subscript/1` mark rendering
- `strikethrough/1` mark rendering
- Delegate module overriding marks (not just node types)

**Recommended tests:**

```elixir
# Add to test/cf_sync/rich_text_renderer_test.exs

test "Renders superscript marks" do
  assert_renders(
    %RichText{type: :text, value: "2", marks: [:superscript]},
    ~s(<sup>2</sup>)
  )
end

test "Renders subscript marks" do
  assert_renders(
    %RichText{type: :text, value: "H2O", marks: [:subscript]},
    ~s(<sub>H2O</sub>)
  )
end

test "Renders strikethrough marks" do
  assert_renders(
    %RichText{type: :text, value: "deleted", marks: [:strikethrough]},
    ~s(<s>deleted</s>)
  )
end

test "Delegate module can override marks" do
  # Test that a delegate module can provide custom :bold, :italic rendering
end
```

### 4. HTTPoison Client - Error Scenarios

**File:** `lib/cf_sync/http_client/httpoison.ex`

**Missing coverage for:**
- Network/connection errors
- SSL/TLS errors
- Timeout handling
- Malformed JSON responses

**Recommended tests:**

```elixir
# Add to test/cf_sync/http_client/httpoison_test.exs

test "returns error tuple on connection refused" do
  expect(FakeHTTPoison, :get, fn _url, _headers, _opts ->
    {:error, %HTTPoison.Error{reason: :econnrefused}}
  end)

  assert {:error, :econnrefused} = HTTPoison.fetch("http://...", "token")
end

test "returns error tuple on timeout" do
  expect(FakeHTTPoison, :get, fn _url, _headers, _opts ->
    {:error, %HTTPoison.Error{reason: :timeout}}
  end)

  assert {:error, :timeout} = HTTPoison.fetch("http://...", "token")
end

test "returns error tuple on SSL error" do
  expect(FakeHTTPoison, :get, fn _url, _headers, _opts ->
    {:error, %HTTPoison.Error{reason: {:tls_alert, 'certificate unknown'}}}
  end)

  assert {:error, _} = HTTPoison.fetch("http://...", "token")
end
```

### 5. Extractors - Error Logging Path

**File:** `lib/cf_sync/entry/extractors.ex`

The `try_link/3` rescue block (lines 312-318) is not tested.

**Recommended tests:**

```elixir
# Add to test/cf_sync/entry/extractors_test.exs

test "extract_link/3 logs error and returns default for malformed link data" do
  import ExUnit.CaptureLog

  data = %{
    fields: %{"link_field" => %{"en_US" => %{"completely" => "invalid"}}},
    locales: %{nil: "en_US"},
    store: make_ref(),
    locale: nil
  }

  {result, log} = with_log(fn ->
    Extractors.extract_link(data, "link_field", default: :fallback)
  end)

  assert result == :fallback
  assert log =~ "Bad link data"
end
```

### 6. Store - Dump File Error Path

**File:** `lib/cf_sync/store.ex`

The `handle_info/2` clause for dump files (lines 121-140) lacks tests for:
- Successful dump file reading
- Error handling when dump file is unreadable

**Recommended tests:**

```elixir
# Add to test/cf_sync/store_test.exs

describe "dump file loading" do
  test "loads entries from dump file on startup" do
    # Create a temp dump file, start store with use_dump_file: "name"
    # Verify entries are loaded
  end

  test "raises when dump file cannot be read" do
    assert_raise RuntimeError, ~r/Unable to read/, fn ->
      start_store(use_dump_file: "nonexistent_dump")
    end
  end
end
```

---

## Lower Priority Improvements

### 7. Edge Cases and Stress Testing

**Recommended additions:**

```elixir
# Concurrent access tests
test "handles concurrent reads safely" do
  # Spawn multiple processes reading from store simultaneously
end

# Large payload handling
test "handles entries with many fields" do
  # Create entry with 100+ fields
end

# Malformed data resilience
test "handles malformed Contentful payload gracefully" do
  # Missing required sys fields, null values, etc.
end
```

### 8. Integration Test Improvements

The current integration test (`test/cf_sync/integration/cf_sync_test.exs`) could benefit from:

- Multi-locale entry retrieval scenarios
- Asset deletion and re-creation
- Entries with embedded entries/assets in RichText
- Testing `get_entries_for_content_type/3` with non-existent content types

### 9. Property-Based Testing

Consider adding property-based tests (using StreamData) for:

- Extractors with random valid/invalid inputs
- RichText tree construction with arbitrary nesting
- Link resolution with random IDs

---

## Test Infrastructure Improvements

### 1. Add Test Coverage Reporting

The project has `excoveralls` configured but consider adding:

```elixir
# mix.exs - add minimum coverage threshold
def project do
  [
    # ...
    test_coverage: [tool: ExCoveralls, minimum: 80],
    # ...
  ]
end
```

### 2. Add Coveralls Configuration

Update `coveralls.json` to:
- Remove `treat_no_relevant_lines_as_covered: true` for stricter coverage
- Add threshold enforcement

### 3. Consider Adding Credo and Dialyzer

```elixir
# mix.exs deps
{:credo, "~> 1.7", only: [:dev, :test], runtime: false},
{:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
```

---

## Summary of Recommended Actions

| Priority | Action | Effort |
|----------|--------|--------|
| 🔴 High | Add tests for Mix tasks (utils, dump, setup) | Medium |
| 🔴 High | Add unit tests for CFSync main module edge cases | Low |
| 🟡 Medium | Add missing mark tests in RichTextRenderer | Low |
| 🟡 Medium | Add HTTP error scenario tests | Low |
| 🟡 Medium | Add extractors error logging test | Low |
| 🟡 Medium | Add Store dump file tests | Medium |
| 🟢 Low | Add concurrent access tests | Medium |
| 🟢 Low | Add property-based tests | High |
| 🟢 Low | Configure coverage thresholds | Low |

---

## Files to Create

1. `test/cf_sync_test.exs` - Unit tests for main CFSync module
2. `test/mix/tasks/utils_test.exs` - Tests for task utilities
3. `test/mix/tasks/cf_sync.dump_test.exs` - Tests for dump task
4. `test/mix/tasks/cf_sync.setup_test.exs` - Tests for setup task

## Files to Modify

1. `test/cf_sync/rich_text_renderer_test.exs` - Add mark tests
2. `test/cf_sync/http_client/httpoison_test.exs` - Add error tests
3. `test/cf_sync/entry/extractors_test.exs` - Add error path test
4. `test/cf_sync/store_test.exs` - Add dump file tests

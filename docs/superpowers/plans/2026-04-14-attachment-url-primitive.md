# Attachment URL Primitive Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enhance `ActiveShrine::Attachment#url` to accept a variant and a `strict:` kwarg, replacing the caller-side boilerplate for Shrine's two-phase upload lifecycle.

**Architecture:** A single small change to `Attachment#url` (lib/active_shrine/attachment.rb:40). Non-strict default returns cache URL during pending; strict mode returns nil until promotion. Variant-missing falls back to original. The delegation in `Attached::One` / `Attached::Many` (via `delegate_missing_to :attachment, allow_nil: true`) propagates the new signature automatically — no changes needed there.

**Tech Stack:** Ruby, Shrine, Minitest, Combustion.

**User Verification:** NO — no user verification required. Automated tests cover the full matrix.

---

## File Structure

- **Modify:** `lib/active_shrine/attachment.rb` — enhance the `url` method in `AttachmentMethods`.
- **Modify:** `test/internal/config/initializers/shrine.rb` — add the `derivatives` plugin so tests can exercise variant URLs.
- **Create:** `test/attachment_test.rb` — covers the full strict/non-strict × cached/stored × variant matrix.

## Task 1: Enable derivatives in test shrine config

**Goal:** Add the Shrine `derivatives` plugin to the test environment so tests can attach, promote, and read variant URLs.

**Files:**
- Modify: `test/internal/config/initializers/shrine.rb`

**Acceptance Criteria:**
- [ ] `Shrine.plugin :derivatives` is loaded in the test init file.
- [ ] `bundle exec rake test` still runs (no regressions in existing tests).

**Verify:** `bundle exec rake test` → existing tests pass.

**Steps:**

- [ ] **Step 1: Add the derivatives plugin**

Edit `test/internal/config/initializers/shrine.rb`. Add this line after the existing plugin calls (e.g. after `Shrine.plugin :refresh_metadata`):

```ruby
Shrine.plugin :derivatives
```

- [ ] **Step 2: Run existing tests**

Run: `bundle exec rake test`
Expected: All existing tests continue to pass.

- [ ] **Step 3: Commit**

```bash
git add test/internal/config/initializers/shrine.rb
git commit -m "test: enable Shrine derivatives plugin in test config"
```

## Task 2: Implement `Attachment#url` with variant + strict support

**Goal:** Replace the no-arg `url` method with a signature that accepts a variant and a `strict:` kwarg, with TDD driving the full behavior matrix.

**Files:**
- Create: `test/attachment_test.rb`
- Modify: `lib/active_shrine/attachment.rb` (method at line 40-42)

**Acceptance Criteria:**
- [ ] `Attachment#url` accepts `(variant = nil, strict: false)`.
- [ ] Non-strict, no variant, stored → returns original storage URL.
- [ ] Non-strict, no variant, cached → returns cache URL.
- [ ] Non-strict, variant, stored, derivative present → returns variant URL.
- [ ] Non-strict, variant, stored, derivative absent → falls back to original URL.
- [ ] Non-strict, variant, cached → falls back to cache URL.
- [ ] Strict, no variant, stored → returns original URL.
- [ ] Strict, no variant, cached → returns nil.
- [ ] Strict, variant, stored, derivative present → returns variant URL.
- [ ] Strict, variant, stored, derivative absent → falls back to original URL.
- [ ] Strict, variant, cached → returns nil.
- [ ] No existing caller that passes zero args is broken.

**Verify:** `bundle exec rake test TEST=test/attachment_test.rb` → all 11 cases pass.

**Steps:**

- [ ] **Step 1: Write the failing test file**

Create `test/attachment_test.rb` with the full matrix. This uses `TestModel` (has_one_attached :file), attaches a real uploaded file, and toggles between cached and stored states by saving the record (which triggers promotion via the inline background blocks in the test setup — the test forces synchronous promotion by calling `file_attacher.promote` directly so we don't depend on ActiveJob).

```ruby
require "test_helper"
require "stringio"

class AttachmentUrlTest < Minitest::Test
  def setup
    @model = TestModel.create!
    io = StringIO.new("hello world")
    io.define_singleton_method(:original_filename) { "hello.txt" }
    io.define_singleton_method(:content_type) { "text/plain" }
    @model.file = io
    @model.save!
    @attachment = @model.file_attachment
  end

  def teardown
    @model&.file_attacher&.destroy
    @model&.destroy
  end

  # --- helpers -------------------------------------------------------------

  def promote!
    @attachment.file_attacher.promote
    @attachment.save!
  end

  def add_thumb_derivative!
    promote!
    thumb_io = StringIO.new("thumb bytes")
    @attachment.file_attacher.add_derivatives(thumb: thumb_io)
    @attachment.save!
  end

  # --- non-strict (default) ------------------------------------------------

  def test_non_strict_no_variant_stored_returns_original_url
    promote!
    assert_match %r{/uploads/}, @attachment.url
    refute_match %r{/uploads/cache/}, @attachment.url
  end

  def test_non_strict_no_variant_cached_returns_cache_url
    assert_match %r{/uploads/cache/}, @attachment.url
  end

  def test_non_strict_variant_stored_with_derivative_returns_variant_url
    add_thumb_derivative!
    assert_match %r{/uploads/.+/thumb}, @attachment.url(:thumb)
  end

  def test_non_strict_variant_stored_without_derivative_falls_back_to_original
    promote!
    url = @attachment.url(:thumb)
    assert_match %r{/uploads/}, url
    refute_match %r{thumb}, url
  end

  def test_non_strict_variant_cached_falls_back_to_cache_url
    assert_match %r{/uploads/cache/}, @attachment.url(:thumb)
  end

  # --- strict --------------------------------------------------------------

  def test_strict_no_variant_stored_returns_original_url
    promote!
    assert_match %r{/uploads/}, @attachment.url(strict: true)
  end

  def test_strict_no_variant_cached_returns_nil
    assert_nil @attachment.url(strict: true)
  end

  def test_strict_variant_stored_with_derivative_returns_variant_url
    add_thumb_derivative!
    assert_match %r{/uploads/.+/thumb}, @attachment.url(:thumb, strict: true)
  end

  def test_strict_variant_stored_without_derivative_falls_back_to_original
    promote!
    url = @attachment.url(:thumb, strict: true)
    assert_match %r{/uploads/}, url
    refute_match %r{thumb}, url
  end

  def test_strict_variant_cached_returns_nil
    assert_nil @attachment.url(:thumb, strict: true)
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bundle exec rake test TEST=test/attachment_test.rb`
Expected: failures — some pass (the no-arg stored case already works), but tests passing kwargs or variants will fail with `ArgumentError: wrong number of arguments` because the current `url` method takes zero arguments.

- [ ] **Step 3: Update `Attachment#url`**

In `lib/active_shrine/attachment.rb`, replace the existing method (lines 40-42):

```ruby
      def url
        file_url
      end
```

with:

```ruby
      # Returns a URL for this attachment.
      #
      # @param variant [Symbol, nil] derivative name (e.g. :thumb). If the
      #   derivative does not exist, falls back to the original.
      # @param strict [Boolean] when true, returns nil unless the file has
      #   been promoted to permanent storage. Defaults to false, which returns
      #   the cache URL during the pending window so uploads are visible
      #   immediately.
      def url(variant = nil, strict: false)
        attacher = file_attacher
        return nil if strict && !attacher.stored?

        (variant && attacher.url(variant)) || attacher.url
      end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bundle exec rake test TEST=test/attachment_test.rb`
Expected: all 11 test cases pass.

- [ ] **Step 5: Run the full test suite for regressions**

Run: `bundle exec rake test`
Expected: no regressions in existing tests (the new signature is backward-compatible — existing `url` callers pass zero args and still work).

- [ ] **Step 6: Commit**

```bash
git add lib/active_shrine/attachment.rb test/attachment_test.rb
git commit -m "feat: support variant and strict mode in Attachment#url"
```

---

## Self-Review

- **Spec coverage:** both design decisions from the spec (enhance rather than add, lenient default, variant fallback to original) are covered in Task 2. Test matrix matches the spec's "Tests" section 1:1.
- **Placeholder scan:** no TBD/TODO; all code blocks are concrete.
- **Type consistency:** `variant`, `strict:`, `file_attacher`, `stored?` used consistently across plan, code, and tests.
- **Verification requirement scan:** NO — spec contains no human-in-the-loop verification requirement.

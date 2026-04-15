# Attachment URL primitive

## Problem

`ActiveShrine::Attachment#url` (lib/active_shrine/attachment.rb:40) delegates
to Shrine's `file_url` with no variant handling and no awareness of Shrine's
two-phase upload lifecycle (cache → promotion → stored). Callers end up
reimplementing the same safety logic repeatedly:

```ruby
def image_url(variant = nil)
  attacher = image_attachment&.file_attacher
  return nil unless attacher&.stored?
  variant ? (attacher.url(variant) || attacher.url) : attacher.url
end
```

This duplicates three concerns that belong in the gem:

1. Skipping the cache phase.
2. Falling back to the original when a derivative is missing.
3. Passing a variant through at all.

## Design

Enhance `Attachment#url` to accept a variant and a `strict:` kwarg. No new
method — there should be one way to get a URL for an attachment.

```ruby
# Returns a URL for this attachment.
#
# @param variant [Symbol, nil] derivative name (e.g. :thumb). If the
#   derivative does not exist, falls back to the original.
# @param strict [Boolean] when true, returns nil unless the file has been
#   promoted to permanent storage. Defaults to false, which returns the
#   cache URL during the pending window so uploads are visible immediately.
def url(variant = nil, strict: false)
  attacher = file_attacher
  return nil if strict && !attacher.stored?

  (variant && attacher.url(variant)) || attacher.url
end
```

### Fallback chain

Non-strict (default):

```
variant URL (if stored & derivative exists)
  → original storage URL (if stored)
  → cache URL (if still pending)
  → nil (nothing attached)
```

Strict:

```
variant URL (if derivative exists)
  → original storage URL
  → nil (anything not yet promoted)
```

### Call sites

`Attached::One` and `Attached::Many` use `delegate_missing_to :attachment,
allow_nil: true` (lib/active_shrine/attached/one.rb:28), so the new signature
flows through automatically:

```ruby
user.avatar.url                       # original; cache URL during pending
user.avatar.url(:thumb)               # thumb → original → cache → nil
user.avatar.url(:thumb, strict: true) # nil until promoted
```

### Design decisions

- **Lenient default, strict opt-in.** Active Storage and CarrierWave return
  a usable URL immediately after attach. Defaulting to nil-until-promoted
  would surprise users by making uploads appear to vanish during background
  processing. The strict mode exists for callers who explicitly want to hide
  half-processed attachments.
- **Enhance `url`, don't add a new method.** Avoids two APIs doing almost
  the same thing. The existing no-arg `url` behavior is preserved.
- **Variant-missing falls back to original.** Derivatives are often
  aspirational — added after the fact, or missing because processing failed.
  A broken `<img>` tag is worse than a wrong-size image.
- **No app-wide default for `strict:`.** Per-call only. Global config invites
  action-at-a-distance bugs, and the kwarg is cheap at the call site.

## Tests

Exercise the full matrix in `spec/active_shrine/attachment_spec.rb` (or
equivalent). Required cases:

**Non-strict (default):**
- No variant, stored → original URL.
- No variant, cached (not stored) → cache URL.
- Variant, stored, derivative exists → variant URL.
- Variant, stored, derivative missing → original URL (fallback).
- Variant, cached → cache URL (fallback through variant/original).

**Strict:**
- No variant, stored → original URL.
- No variant, cached → nil.
- Variant, stored, derivative exists → variant URL.
- Variant, stored, derivative missing → original URL.
- Variant, cached → nil.

Tests should use Shrine's memory storage and derivatives plugin to exercise
real stored/cached/derivative transitions rather than mocking the attacher.

## Out of scope

- Changing `Attached::One`/`Attached::Many` — delegation handles it.
- Any new helper methods (`derivative_url`, `safe_url`, etc.).
- Configuration hooks or initializers.
- Changes to `representable?`, `content_type`, or other attachment metadata.

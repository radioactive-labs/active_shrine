require "test_helper"
require "stringio"

class AttachmentUrlTest < Minitest::Test
  # Minimal 1x1 transparent PNG — avoids the text/plain branch in the
  # test shrine config (which falls through to an unloaded mime/types gem).
  PNG_BYTES = [
    "89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c489",
    "0000000d49444154789c6300010000000500010d0a2db40000000049454e44ae426082"
  ].join.scan(/../).map { |h| h.to_i(16) }.pack("C*").freeze

  def setup
    @model = TestModel.create!
    io = StringIO.new(PNG_BYTES.dup)
    io.define_singleton_method(:original_filename) { "pixel.png" }
    io.define_singleton_method(:content_type) { "image/png" }
    @model.file = io
    @model.save!
    @attachment = @model.file_attachment
  end

  def teardown
    @attachment&.file_attacher&.destroy
    @model&.destroy
  end

  def promote!
    @attachment.file_attacher.promote
    @attachment.save!
  end

  def add_thumb_derivative!
    promote!
    thumb_io = StringIO.new(PNG_BYTES.dup)
    @attachment.file_attacher.add_derivatives({thumb: thumb_io})
    @attachment.save!
  end

  def test_non_strict_no_variant_stored_returns_original_url
    promote!
    url = @attachment.url
    assert_match %r{/uploads/}, url
    refute_match %r{/uploads/cache/}, url
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

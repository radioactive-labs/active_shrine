require "test_helper"
require "stringio"

class CreateManyValidationTest < Minitest::Test
  PNG_BYTES = [
    "89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c489",
    "0000000d49444154789c6300010000000500010d0a2db40000000049454e44ae426082"
  ].join.scan(/../).map { |h| h.to_i(16) }.pack("C*").freeze

  def make_io(name = "pixel.png")
    io = StringIO.new(PNG_BYTES.dup)
    io.define_singleton_method(:original_filename) { name }
    io.define_singleton_method(:content_type) { "image/png" }
    io
  end

  def teardown
    @model&.validated_files_attachments&.each do |a|
      a.file_attacher.destroy
    rescue
      nil
    end
    @model&.destroy
  end

  def test_raises_record_invalid_when_a_file_fails_validation
    @model = TestModel.create!
    @model.validated_files = [make_io]

    assert_raises(ActiveRecord::RecordInvalid) { @model.save! }
  end

  def test_bridges_attacher_errors_to_record_errors_by_name
    @model = TestModel.create!
    @model.validated_files = [make_io]

    begin
      @model.save!
    rescue ActiveRecord::RecordInvalid
      # expected
    end

    refute_empty @model.errors[:validated_files]
    assert_match(/too large/, @model.errors[:validated_files].first)
  end

  def test_collects_errors_from_all_invalid_files
    @model = TestModel.create!
    @model.validated_files = [make_io("a.png"), make_io("b.png")]

    begin
      @model.save!
    rescue ActiveRecord::RecordInvalid
      # expected
    end

    assert_equal 2, @model.errors[:validated_files].size
  end
end

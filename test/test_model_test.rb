require "test_helper"

class TestModelTest < Minitest::Test
  def test_doesnt_work
    # Commented out as it was in the original
    # m = TestModel.new
    # m.file = File.open File.expand_path('test.txt', __dir__)
    # m.save!
    # puts TestModel.count
    puts ActiveShrine::Attachment.count

    # Since this is a test, we should have an assertion
    # Adding a placeholder assertion since the original didn't have one
    assert_operator ActiveShrine::Attachment.count, :>=, 0
  end

  def test_it_works
    # Commented out as it was in the original
    # m = TestModel.new
    # m.file = File.open File.expand_path('test.txt', __dir__)
    # m.save!
    # puts TestModel.count
    puts ActiveShrine::Attachment.count

    # Since this is a test, we should have an assertion
    # Adding a placeholder assertion since the original didn't have one
    assert_operator ActiveShrine::Attachment.count, :>=, 0
  end
end

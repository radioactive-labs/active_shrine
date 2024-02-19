require "spec_helper"
require "generators/active_shrine/install/install_generator"

describe TestModel do
  let(:generator) { ActiveShrine::InstallGenerator }
  let(:destination_root) { File.expand_path("internal", __dir__) }

  before do
    generator.start [], destination_root: destination_root, behavior: :invoke
  end

  after do
    # generator.start [], destination_root: destination_root, behavior: :revoke
  end

  fit "doesn't works" do
    # m = TestModel.new
    # m.file = File.open File.expand_path('test.txt', __dir__)
    # m.save!
    # puts TestModel.count
    puts ActiveShrine::Attachment.count
  end
  it "works" do
    # m = TestModel.new
    # m.file = File.open File.expand_path('test.txt', __dir__)
    # m.save!
    # puts TestModel.count
    puts ActiveShrine::Attachment.count
  end
end

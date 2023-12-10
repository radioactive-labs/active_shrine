require 'spec_helper.rb'
require 'generators/shrine_storage/install/install_generator.rb'

describe TestModel do 
    
    let(:generator) { ShrineStorage::InstallGenerator }
    let(:destination_root) { File.expand_path('internal', __dir__) }
    
    before do 
        generator.start [], destination_root: destination_root, behavior: :invoke 
    end

    after do 
        # generator.start [], destination_root: destination_root, behavior: :revoke
    end

    it 'works' do
        # m = TestModel.new
        # m.file = File.open File.expand_path('test.txt', __dir__)
        # m.save!
        # puts TestModel.count 
        puts ShrineAttachment.count
    end
end
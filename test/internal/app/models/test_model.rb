class ValidatedUploader < Shrine
  plugin :validation_helpers

  Attacher.validate do
    validate_max_size 10, message: "is too large"
  end
end

class TestModel < ActiveRecord::Base
  include ActiveShrine::Model
  has_one_attached :file
  has_many_attached :files
  has_many_attached :validated_files, uploader: ::ValidatedUploader
end

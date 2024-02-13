class TestModel < ActiveRecord::Base 
  include ActiveShrine::Model
  has_one_attached :file
  has_many_attached :files

end
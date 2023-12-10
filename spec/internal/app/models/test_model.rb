class TestModel < ActiveRecord::Base 
  include ShrineStorage::Model
  has_one_attached :file
  has_many_attached :files

end
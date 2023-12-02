# frozen_string_literal: true

require_relative "shrine_storage/version"
require_relative "shrine_storage/railtie"

module ShrineStorage
  extend ActiveSupport::Autoload

  class Error < StandardError; end
  # Your code goes here...
  eager_autoload do
    autoload :Attached
    autoload :Changes
    autoload :Many
    autoload :Model
    autoload :One
  end

end

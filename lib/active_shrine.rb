# frozen_string_literal: true

require_relative "active_shrine/version"
require_relative "active_shrine/railtie"

module ActiveShrine
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

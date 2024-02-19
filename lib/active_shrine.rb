# frozen_string_literal: true

require_relative "active_shrine/version"
require_relative "active_shrine/railtie"

module ActiveShrine
  extend ActiveSupport::Autoload

  class Error < StandardError; end

  eager_autoload do
    autoload :Attached
    autoload :Attachment
    autoload :Job
    autoload :Model
    autoload :Reflection
  end
end

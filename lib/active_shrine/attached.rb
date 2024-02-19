# frozen_string_literal: true

module ActiveShrine
  module Attached # :nodoc:
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Base
      autoload :Changes
      autoload :Many
      autoload :One
    end
  end
end

# frozen_string_literal: true

module ActiveShrine
  module Attached
    module Changes # :nodoc:
      extend ActiveSupport::Autoload

      eager_autoload do
        autoload :CreateOne
        autoload :CreateMany
        autoload :CreateOneOfMany

        autoload :DeleteOne
        autoload :DeleteMany

        autoload :DetachOne
        autoload :DetachMany

        autoload :PurgeOne
        autoload :PurgeMany
      end
    end
  end
end

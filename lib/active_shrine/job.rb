# frozen_string_literal: true

module ActiveShrine
  module Changes # :nodoc:
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :PromoteShrineAttachment
      autoload :DestroyShrineAttachment
    end
  end
end

# frozen_string_literal: true

require "shrine"
module ActiveShrine
  module Job
    module DestroyShrineAttachment
      private

      def perform(attacher_class, data)
        attacher_class = attacher_class.constantize

        attacher = attacher_class.from_data(data)
        attacher.destroy
      end
    end
  end
end

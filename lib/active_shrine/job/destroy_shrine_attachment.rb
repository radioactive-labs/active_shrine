# frozen_string_literal: true

require "shrine"

module ActiveShrine
  module Job
    module DestroyShrineAttachment
      private

      def perform(attacher_class, record_class, data)
        record_class.constantize # materialize the uploader polymorphic class
        attacher_class = attacher_class.constantize

        attacher = attacher_class.from_data(data)
        attacher.destroy
      end
    end
  end
end

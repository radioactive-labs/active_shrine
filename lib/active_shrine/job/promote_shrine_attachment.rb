# frozen_string_literal: true

require "shrine"

module ActiveShrine
  module Job
    module PromoteShrineAttachment
      private

      def perform(attacher_class, record_class, record_id, name, file_data)
        attacher_class = attacher_class.constantize
        record = record_class.constantize.find(record_id)

        attacher = attacher_class.retrieve(model: record, name:, file: file_data)
        attacher.atomic_promote
      rescue Shrine::AttachmentChanged, ActiveRecord::RecordNotFound
        # attachment has changed or record has been deleted, nothing to do
      end
    end
  end
end

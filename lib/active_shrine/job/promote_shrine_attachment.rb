# frozen_string_literal: true

require "shrine"

module ActiveShrine
  module Job
    module PromoteShrineAttachment
      private

      def perform(attacher_class, attachment_record_class, attachment_record_id, record_class, attribute_name, file_data)
        record_class.constantize # materialize the uploader polymorphic class
        attachment_record = attachment_record_class.constantize.find(attachment_record_id)
        attacher = attacher_class.constantize.retrieve(model: attachment_record, name: attribute_name, file: file_data)
        attacher.atomic_promote
      rescue Shrine::AttachmentChanged, ActiveRecord::RecordNotFound
        # attachment has changed or record has been deleted, nothing to do
      end
    end
  end
end

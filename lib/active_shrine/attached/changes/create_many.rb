# frozen_string_literal: true

module ActiveShrine
  module Attached
    module Changes
      class CreateMany # :nodoc:
        attr_reader :name, :record, :attachment_class, :attachables, :pending_uploads

        def initialize(name, record, attachment_class, attachables, pending_uploads: [])
          @name = name
          @record = record
          @attachment_class = attachment_class
          @attachables = Array(attachables)
          @pending_uploads = Array(pending_uploads) + subchanges
          attachments
        end

        def attachments
          @attachments ||= subchanges.collect(&:attachment)
        end

        def save
          assign_associated_attachments
        end

        private

        def subchanges
          @subchanges ||= attachables.collect { |attachable| build_subchange_from(attachable) }
        end

        def build_subchange_from(attachable)
          Attached::Changes::CreateOneOfMany.new(name, record, attachment_class, attachable)
        end

        def assign_associated_attachments
          record.public_send(:"#{name}_attachments=", persisted_or_new_attachments)
        end

        def persisted_or_new_attachments
          attachments.select { |attachment| attachment.persisted? || attachment.new_record? }
        end
      end
    end
  end
end

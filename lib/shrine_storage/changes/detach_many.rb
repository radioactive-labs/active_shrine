# frozen_string_literal: true

module ShrineStorage
  module Changes
    class DetachMany # :nodoc:
      attr_reader :name, :record, :attachments

      def initialize(name, record, attachments)
        @name = name
        @record = record
        @attachments = attachments
      end

      def detach
        return unless attachments.any?

        attachments.delete_all if attachments.respond_to?(:delete_all)
        record.shrine_attachment_changes.delete(name)
      end
    end
  end
end

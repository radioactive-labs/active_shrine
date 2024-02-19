# frozen_string_literal: true

module ActiveShrine
  module Changes
    class DeleteMany # :nodoc:
      attr_reader :name, :record

      def initialize(name, record)
        @name = name
        @record = record
      end

      def attachables
        []
      end

      def attachments
        ActiveShrine::Attachment.none
      end

      def save
        record.public_send(:"#{name}_attachments=", [])
      end
    end
  end
end

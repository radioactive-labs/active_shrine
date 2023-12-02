# frozen_string_literal: true

module ShrineStorage
  module Changes
    class DetachOne # :nodoc:
      attr_reader :name, :record, :attachment

      def initialize(name, record, attachment)
        @name = name
        @record = record
        @attachment = attachment
      end

      def detach
        return unless attachment.present?

        attachment.delete
        reset
      end

      private

      def reset
        record.shrine_attachment_changes.delete(name)
        record.public_send("#{name}_attachment=", nil)
      end
    end
  end
end

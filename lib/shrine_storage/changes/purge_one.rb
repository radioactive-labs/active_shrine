# frozen_string_literal: true

module ShrineStorage
  module Changes
    class PurgeOne # :nodoc:
      attr_reader :name, :record, :attachment

      def initialize(name, record, attachment)
        @name = name
        @record = record
        @attachment = attachment
      end

      def purge
        attachment&.purge
        reset
      end

      def purge_later
        attachment&.purge_later
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

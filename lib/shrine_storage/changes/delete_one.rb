# frozen_string_literal: true

module ShrineStorage
  module Changes
    class DeleteOne # :nodoc:
      attr_reader :name, :record

      def initialize(name, record)
        @name = name
        @record = record
      end

      def attachment
        nil
      end

      def save
        record.public_send("#{name}_attachment=", nil)
      end
    end
  end
end

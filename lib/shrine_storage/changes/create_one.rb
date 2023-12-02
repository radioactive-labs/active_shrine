# frozen_string_literal: true

require 'action_dispatch'
require 'action_dispatch/http/upload'

module ShrineStorage
  module Changes
    class CreateOne # :nodoc:
      attr_reader :name, :record, :attachable

      def initialize(name, record, attachable)
        @name = name
        @record = record
        @attachable = attachable

        attach
      end

      def attachment
        @attachment ||= find_or_build_attachment
      end

      def save
        record.public_send("#{name}_attachment=", attachment)
      end

      private

      def attach
        attachment.file = attachable
        attachment
      end

      def find_or_build_attachment
        find_attachment || build_attachment
      end

      def find_attachment
        attachment = record.public_send("#{name}_attachment")

        attachment if attachable.is_a?(String) && attachment&.signed_id == attachable
      end

      def build_attachment
        ShrineAttachment.new(record:, name:)
      end
    end
  end
end

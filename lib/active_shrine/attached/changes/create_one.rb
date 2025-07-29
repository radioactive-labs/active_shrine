# frozen_string_literal: true

require "action_dispatch"
require "action_dispatch/http/upload"

module ActiveShrine
  module Attached
    module Changes
      class CreateOne # :nodoc:
        attr_reader :name, :record, :attachment_class, :attachable

        def initialize(name, record, attachment_class, attachable)
          @name = name
          @record = record
          @attachment_class = attachment_class
          @attachable = attachable

          attach
        end

        def attachment
          @attachment ||= find_or_build_attachment
        end

        def save
          unless attachment.valid?
            attachment.errors.each do |error|
              record.errors.add(name, error.message)
            end

            raise ActiveRecord::RecordInvalid.new(record)
          end

          record.public_send(:"#{name}_attachment=", attachment)
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
          attachment = record.public_send(:"#{name}_attachment")

          attachment if attachable.is_a?(String) && attachment&.signed_id == attachable
        end

        def build_attachment
          attachment_class.new(record:, name:)
        end
      end
    end
  end
end

# frozen_string_literal: true

module ShrineStorage
  module Changes
    class CreateOneOfMany < Changes::CreateOne # :nodoc:
      private

      def find_attachment
        record.public_send("#{name}_attachments").detect do |attachment|
          attachable.is_a?(String) && attachment.signed_id == attachable
        end
      end
    end
  end
end

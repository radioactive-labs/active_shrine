# frozen_string_literal: true

require "shrine"

# == Schema Information
#
# Table name: active_shrine_attachments
#
#  id          :bigint           not null, primary key
#  file_data   :jsonb            not null
#  metadata    :jsonb            not null
#  name        :string           not null
#  record_type :string
#  type        :string           default("ActiveShrine::Attachment"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  record_id   :bigint
#
# Indexes
#
#  active_shrine_attachments_on_file_data  (file_data) USING gin
#  active_shrine_attachments_on_metadata   (metadata) USING gin
#  active_shrine_attachments_on_name       (name)
#  active_shrine_attachments_on_record     (record_type,record_id)
#
module ActiveShrine
  class Attachment < ActiveRecord::Base
    include ActiveModel::Serializers::JSON

    self.table_name = "active_shrine_attachments"

    belongs_to :record, polymorphic: true, optional: true

    validates :name, presence: true
    validates :file_data, presence: true

    before_save :maybe_store_record

    module AttachmentMethods
      def url
        file_url
      end

      def content_type
        file.mime_type
      end

      def filename
        file.original_filename
      end

      def extension
        file.extension
      end

      def representable?
        %r{image/.*}.match? content_type
      end

      def signed_id
        # add the id to ensure uniqueness
        value = ({id:, file: file.to_json} if file.present?) || {}
        Rails.application.message_verifier(:active_shrine_attachment).generate value
      end

      def file=(value)
        # It is the same file. we are good to go.
        return if value == signed_id

        if value.is_a?(String)
          # it is an already uploaded file. either
          # - via direct upload so the form is sending us a json hash to set
          # - or was set because a previous submission failed, so the form is sending us the signed_id
          begin
            # attempt to parse as a json hash
            value = JSON.parse value
          rescue JSON::ParserError
            # this is not a valid json hash, let's check if it is a valid signed_id
            unsigned = Rails.application.message_verifier(:active_shrine_attachment).verify value
            value = JSON.parse unsigned["file"]
          end
        end

        super
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        errors.add(:file, "is invalid")
      end

      def purge
        file_attacher.destroy_block { destroy } if file_attacher.respond_to?(:destroy_block)
        destroy
      end

      def purge_later
        file_attacher.destroy_background
        file_attacher.instance_variable_set :@file, nil # prevent shrine from attempting to destroy the file again
        destroy
      rescue NoMethodError
        raise NotImplementedError, ("You need to enable Shrine backgrounding to use purge_later: " \
                                    "https://shrinerb.com/docs/plugins/backgrounding")
      end

      private

      def maybe_store_record
        return unless record.present?

        metadata.merge! record_type:, record_id:
      end
    end
  end
end

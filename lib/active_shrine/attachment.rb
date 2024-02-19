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
    include Shrine::Attachment(:file)
    include ActiveModel::Serializers::JSON

    self.table_name = "active_shrine_attachments"

    belongs_to :record, polymorphic: true, optional: true

    validates :name, presence: true
    validates :file_data, presence: true

    before_save :maybe_store_record

    def signed_id
      value = ({id:, file: file.to_json, unsafe: metadata["unsafe"]} if file.present?) || {}
      Rails.application.message_verifier(:active_shrine_attachment).generate value
    end

    def file=(value)
      # If it is the same file, we do nothing
      return if value == signed_id

      if value.is_a?(String)
        # if it is an already uploaded file either
        # - in cache (uploaded via direct upload) so the form is sending us a json hash
        # - or in store (already promoted) so the form is sending us the signed_id

        # first mark this as unsafe. the record is not saved yet so this does not hit the db
        # if a failure occurs while trying to save the record
        # then this unsafe value will be encoded in the value returned by #signed_id, which is used to populate the form
        # that way, when a reupload is attempted, value == signed_id above will always be false
        # forcing us to re-validate the value
        metadata["unsafe"] = true
        begin
          # attempt to parse as a json hash
          value = JSON.parse value
        rescue JSON::ParserError
          # this is not a valid json hash, let's check if it is a valid signed_id
          unsigned = Rails.application.message_verifier(:active_shrine_attachment).verify value
          value = unsigned[:file]
          # restore the unsafe value
          debugger
          metadata["unsafe"] = unsigned["unsafe"]
        end
      else
        # else it is either an i/o object or a file hash (from shrine)
        # either way, this is safe now since we know it is being set programmatically
        metadata.delete "unsafe"
      end

      super(value)
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

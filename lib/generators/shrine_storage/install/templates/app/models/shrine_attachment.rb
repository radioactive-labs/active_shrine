# frozen_string_literal: true

# == Schema Information
#
# Table name: shrine_attachments
#
#  id          :bigint           not null, primary key
#  file_data   :jsonb            not null
#  metadata    :jsonb            not null
#  name        :string           not null
#  record_type :string
#  type        :string           default("ShrineAttachment"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  record_id   :bigint
#
# Indexes
#
#  index_shrine_attachments_on_file_data  (file_data) USING gin
#  index_shrine_attachments_on_metadata   (metadata) USING gin
#  index_shrine_attachments_on_name       (name)
#  index_shrine_attachments_on_record     (record_type,record_id)
#
class ShrineAttachment < ApplicationRecord
  include Shrine::Attachment(:file)

  belongs_to :record, polymorphic: true, optional: true

  validates :name, presence: true
  validates :file_data, presence: true

  before_save :maybe_store_record

  def signed_id
    value = ({ id:, file: file.to_json, unsafe: metadata['unsafe'] } if file.present?) || {}
    Rails.application.message_verifier(:attachment).generate value
  end

  def file=(value)
    return if value == signed_id

    # Handle value set from form
    if value.is_a?(String)
      begin
        metadata['unsafe'] = true
        value = JSON.parse value
      rescue JSON::ParserError
        unsigned = Rails.application.message_verifier(:attachment).verify value
        value = unsigned[:file]
        metadata['unsafe'] = unsigned['unsafe']
      end
    else
      metadata.delete 'unsafe'
    end

    super(value)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    errors.add(:file, 'is invalid')
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
    raise NotImplementedError, ('You need to enable Shrine backgrounding to use purge_later: ' \
                                'https://shrinerb.com/docs/plugins/backgrounding')
  end

  def representable?
    %r{image/.*}.match? file.mime_type
  end

  def thumbnail_url
    file_url if representable?
  end

  private

  def maybe_store_record
    return unless record.present?

    metadata.merge! record_type:, record_id:
  end
end

# frozen_string_literal: true

module ActiveShrine
  module Attached
    # = ActiveShrine\Attached\One
    #
    # Representation of a single attachment to a model.
    class One < Base
      ##
      # :method: purge
      #
      # Directly purges the attachment (i.e. destroys the blob and
      # attachment and deletes the file on the service).
      delegate :purge, to: :purge_one

      ##
      # :method: purge_later
      #
      # Purges the attachment through the queuing system.
      delegate :purge_later, to: :purge_one

      ##
      # :method: detach
      #
      # Deletes the attachment without purging it, leaving its blob in place.
      delegate :detach, to: :detach_one

      delegate_missing_to :attachment, allow_nil: true

      # Returns the associated attachment record.
      #
      # You don't have to call this method to access the attachment's methods as
      # they are all available at the model level.
      def attachment
        change.present? ? change.attachment : record.public_send(:"#{name}_attachment")
      end

      # Returns +true+ if an attachment is not attached.
      #
      #   class User < ApplicationRecord
      #     has_one_attached :avatar
      #   end
      #
      #   User.new.avatar.blank? # => true
      def blank?
        !attached?
      end

      # Attaches an +attachable+ to the record.
      #
      # If the record is persisted and unchanged, the attachment is saved to
      # the database immediately. Otherwise, it'll be saved to the DB when the
      # record is next saved.
      #
      #   person.avatar.attach(params[:avatar]) # ActionDispatch::Http::UploadedFile object
      #   person.avatar.attach(params[:signed_id]) # Signed reference to attachment
      #
      #   See https://shrinerb.com/docs/attacher#attaching for more
      def attach(attachable)
        record.public_send(:"#{name}=", attachable)
        if record.persisted? && !record.changed?
          return if !record.save
        end

        record.public_send(:"#{name}")
      end

      # Returns +true+ if an attachment has been made.
      #
      #   class User < ApplicationRecord
      #     has_one_attached :avatar
      #   end
      #
      #   User.new.avatar.attached? # => false
      def attached?
        attachment.present?
      end

      private

      def purge_one
        Attached::Changes::PurgeOne.new(name, record, attachment)
      end

      def detach_one
        Attached::Changes::DetachOne.new(name, record, attachment)
      end
    end
  end
end

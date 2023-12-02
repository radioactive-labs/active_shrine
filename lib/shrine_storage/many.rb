# frozen_string_literal: true

module ShrineStorage
  # = Shrine Storage \Attached \Many
  #
  # Decorated proxy object representing of multiple attachments to a model.
  class Many < Attached
    ##
    # :method: purge
    #
    # Directly purges each associated attachment (i.e. destroys the blobs and
    # attachments and deletes the files on the service).
    delegate :purge, to: :purge_many

    ##
    # :method: purge_later
    #
    # Purges each associated attachment through the queuing system.
    delegate :purge_later, to: :purge_many

    ##
    # :method: detach
    #
    # Deletes associated attachments without purging them, leaving their respective blobs in place.
    delegate :detach, to: :detach_many

    delegate_missing_to :attachments

    # Returns all the associated attachment records.
    #
    # All methods called on this proxy object that aren't listed here will automatically be delegated to +attachments+.
    def attachments
      change.present? ? change.attachments : record.public_send("#{name}_attachments")
    end

    # Attaches one or more +attachables+ to the record.
    #
    # If the record is persisted and unchanged, the attachments are saved to
    # the database immediately. Otherwise, they'll be saved to the DB when the
    # record is next saved.
    #
    #   document.images.attach(params[:images]) # Array of ActionDispatch::Http::UploadedFile objects
    #   person.avatar.attach(params[:signed_id]) # Signed reference to attachment
    #
    #   See https://shrinerb.com/docs/attacher#attaching for more
    def attach(*attachables)
      record.public_send("#{name}=", attachments.map(&:signed_id) + attachables.flatten)
      return if record.persisted? && !record.changed? && !record.save

      record.public_send("#{name}")
    end

    # Returns true if any attachments have been made.
    #
    #   class Gallery < ApplicationRecord
    #     has_many_attached :photos
    #   end
    #
    #   Gallery.new.photos.attached? # => false
    def attached?
      attachments.any?
    end

    private

    def purge_many
      Changes::PurgeMany.new(name, record, attachments)
    end

    def detach_many
      Changes::DetachMany.new(name, record, attachments)
    end
  end
end

# frozen_string_literal: true

module ShrineStorage
  # Provides the class-level DSL for declaring an Active Record model's attachments.
  module Model
    extend ActiveSupport::Concern

    ##
    # :method: *_attachment
    #
    # Returns the attachment for the +has_one_attached+.
    #
    #   User.last.avatar_attachment

    ##
    # :method: *_attachments
    #
    # Returns the attachments for the +has_many_attached+.
    #
    #   Gallery.last.photos_attachments

    ##
    # :method: with_attached_*
    #
    # Includes the attachments in your query to avoid N+1 queries.
    #
    #   User.with_attached_avatar
    #
    # Use the plural form for +has_many_attached+:
    #
    #   Gallery.with_attached_photos

    class_methods do
      # Specifies the relation between a single attachment and the model.
      #
      #   class User < ApplicationRecord
      #     has_one_attached :avatar
      #   end
      #
      # There is no column defined on the model side, Active Storage takes
      # care of the mapping between your records and the attachment.
      #
      # To avoid N+1 queries, you can include the attachments in your query like so:
      #
      #   User.with_attached_avatar
      #
      # Under the covers, this relationship is implemented as a +has_one+ association to a
      # ShrineAttachment record. These associations are available as +avatar_attachment+.
      # But you shouldn't need to work with these associations directly in most circumstances.
      #
      # The system has been designed to having you go through the One
      # proxy that provides the dynamic proxy to the associations and factory methods, like +attach+.
      #
      # If the +:dependent+ option isn't set, the attachment will be destroyed
      # (i.e. deleted from the database and file storage) whenever the record is destroyed.
      #
      # If you need to enable +strict_loading+ to prevent lazy loading of attachment,
      # pass the +:strict_loading+ option. You can do:
      #
      #   class User < ApplicationRecord
      #     has_one_attached :avatar, strict_loading: true
      #   end
      #
      def has_one_attached(name, class_name: 'ShrineAttachment', dependent: :destroy, strict_loading: false)
        generated_association_methods.class_eval <<-CODE, __FILE__, __LINE__ + 1
          # frozen_string_literal: true
          def #{name}
            @shrine_storage_attached ||= {}
            @shrine_storage_attached[:#{name}] ||= One.new("#{name}", self)
          end

          def #{name}=(attachable)
            shrine_attachment_changes["#{name}"] =
              if attachable.presence.nil?
                Changes::DeleteOne.new("#{name}", self)
              else
                Changes::CreateOne.new("#{name}", self, attachable)
              end
          end
        CODE

        has_one(:"#{name}_attachment", -> { where(name:) }, class_name:, as: :record, inverse_of: :record,
                                                            dependent:, strict_loading:)

        scope :"with_attached_#{name}", -> { includes(:"#{name}_attachment") }

        after_save { shrine_attachment_changes[name.to_s]&.save }

        yield reflection if block_given?
      end

      # Specifies the relation between multiple attachments and the model.
      #
      #   class Gallery < ApplicationRecord
      #     has_many_attached :photos
      #   end
      #
      # There are no columns defined on the model side, Active Storage takes
      # care of the mapping between your records and the attachments.
      #
      # To avoid N+1 queries, you can include the attachments in your query like so:
      #
      #   Gallery.where(user: Current.user).with_attached_photos
      #
      # Under the covers, this relationship is implemented as a +has_many+ association to a
      # ShrineAttachment record. These associations are available as +photos_attachments+.
      # But you shouldn't need to work with these associations directly in most circumstances.
      #
      # The system has been designed to having you go through the Many
      # proxy that provides the dynamic proxy to the associations and factory methods, like +#attach+.
      #
      # If the +:dependent+ option isn't set, all the attachments will be destroyed
      # (i.e. deleted from the database and file storage) whenever the record is destroyed.
      #
      # If you need to configure +strict_loading+ to enable lazy loading of attachments,
      # pass the +:strict_loading+ option. You can do:
      #
      #   class Gallery < ApplicationRecord
      #     has_many_attached :photos, strict_loading: true
      #   end
      #
      def has_many_attached(name, class_name: 'ShrineAttachment', dependent: :destroy, strict_loading: false)
        generated_association_methods.class_eval <<-CODE, __FILE__, __LINE__ + 1
        # frozen_string_literal: true
        def #{name}
          @shrine_storage_attached ||= {}
          @shrine_storage_attached[:#{name}] ||= Many.new("#{name}", self)
        end

        def #{name}=(attachables)
          attachables = Array(attachables).compact_blank
          pending_uploads = shrine_attachment_changes["#{name}"].try(:pending_uploads)

          shrine_attachment_changes["#{name}"] = if attachables.none?
            Changes::DeleteMany.new("#{name}", self)
          else
            Changes::CreateMany.new("#{name}", self, attachables, pending_uploads: pending_uploads)
          end
        end
        CODE

        has_many(:"#{name}_attachments", -> { where(name:) }, class_name:, as: :record, inverse_of: :record,
                                                              dependent:, strict_loading:)

        scope :"with_attached_#{name}", -> { includes(:"#{name}_attachments") }

        after_save { shrine_attachment_changes[name.to_s]&.save }

        # after_commit(on: %i[create update]) { shrine_attachment_changes.delete(name.to_s).try(:upload) }

        # reflection = ActiveRecord::Reflection.create(
        #   :has_many_attached,
        #   name,
        #   nil,
        #   { dependent:, service_name: service },
        #   self
        # )
        yield reflection if block_given?
        # ActiveRecord::Reflection.add_attachment_reflection(self, name, reflection)
      end
    end

    def shrine_attachment_changes # :nodoc:
      @shrine_attachment_changes ||= {}
    end

    def changed_for_autosave? # :nodoc:
      super || shrine_attachment_changes.any?
    end

    def initialize_dup(*) # :nodoc:
      super
      @shrine_storage_attached = nil
      @shrine_attachment_changes = nil
    end

    def reload(*) # :nodoc:
      super.tap { @shrine_attachment_changes = nil }
    end
  end
end

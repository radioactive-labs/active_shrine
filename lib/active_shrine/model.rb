# frozen_string_literal: true

module ActiveShrine
  # Provides the class-level DSL for declaring an Active Record model's attachments.
  module Model
    extend ActiveSupport::Concern
    include ActiveShrine::Reflection::ActiveRecordExtensions

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
      private

      # Resolves or creates a custom attachment class for a given uploader.
      #
      # @param uploader [Class] the uploader class (e.g. ::ImageUploader)
      # @return [Class, String] the resolved attachment class and its name
      def resolve_attachment_class(uploader)
        attachment_class_name = "::ActiveShrine::#{uploader}Attachment"

        # Try to find or create the custom attachment class
        attachment_class = begin
          attachment_class_name.constantize
        rescue NameError
          # Dynamically create a new class that inherits from ActiveShrine::Attachment
          Class.new(::ActiveShrine::Attachment) do
            include uploader::Attachment(:file)
          end.tap do |klass|
            # Define the class in the ActiveShrine namespace
            ActiveShrine.const_set(:"#{uploader}Attachment", klass)
          end
        end

        [attachment_class, attachment_class_name]
      end

      public

      # Specifies the relation between a single attachment and the model.
      #
      #   class User < ApplicationRecord
      #     has_one_attached :avatar
      #   end
      #
      # You can specify a custom uploader implementation to use for the attachment:
      #
      #  class ImageUploader < Shrine
      #    plugin :validation_helpers
      #
      #     Attacher.validate do
      #       validate_max_size 10 * 1024 * 1024
      #     end
      #   end
      #
      #   class User < ApplicationRecord
      #     has_one_attached :avatar, uploader: ::ImageUploader
      #   end
      #
      # There is no column defined on the model side, ActiveShrine takes
      # care of the mapping between your records and the attachment.
      #
      # To avoid N+1 queries, you can include the attachments in your query like so:
      #
      #   User.with_attached_avatar
      #
      # Under the covers, this relationship is implemented as a +has_one+ association to a
      # ActiveShrine::Attachment record. These associations are available as +avatar_attachment+.
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
      # Note: ActiveShrine relies on polymorphic associations, which in turn store class names in the database.
      # When renaming classes that use <tt>has_many</tt>, make sure to also update the class names in the
      # <tt>active_shrine_attachments.record_type</tt> polymorphic type column of
      # the corresponding rows.
      def has_one_attached(name, uploader: ::Shrine, dependent: :destroy, strict_loading: false)
        attachment_class, attachment_class_name = resolve_attachment_class(uploader)

        generated_association_methods.class_eval <<-CODE, __FILE__, __LINE__ + 1
          # frozen_string_literal: true
          def #{name}
            @active_shrine_attached ||= {}
            @active_shrine_attached[:#{name}] ||= Attached::One.new("#{name}", self)
          end

          def #{name}=(attachable)
            shrine_attachment_changes["#{name}"] =
              if attachable.presence.nil?
                Attached::Changes::DeleteOne.new("#{name}", self)
              else
                Attached::Changes::CreateOne.new("#{name}", self, #{attachment_class}, attachable)
              end
          end
        CODE

        has_one(:"#{name}_attachment",
          -> { where(name:) },
          class_name: attachment_class_name,
          as: :record,
          inverse_of: :record,
          dependent: dependent,
          strict_loading: strict_loading)

        scope :"with_attached_#{name}", -> { includes(:"#{name}_attachment") }

        after_save do
          shrine_attachment_changes[name.to_s]&.save
        rescue => e
          errors.add(name, :invalid, message: "failed to save. Please make sure it is a valid file.")
          raise ActiveRecord::RecordInvalid.new(self)
        end

        after_commit(on: %i[create update]) { shrine_attachment_changes.delete(name.to_s) }

        reflection = ActiveRecord::Reflection.create(
          :has_one_attached,
          name,
          nil,
          {dependent: dependent, class_name: attachment_class_name, source: :active_shrine},
          self
        )
        yield reflection if block_given?
        ActiveRecord::Reflection.add_shrine_attachment_reflection(self, name, reflection)
      end

      # Specifies the relation between multiple attachments and the model.
      #
      #   class Gallery < ApplicationRecord
      #     has_many_attached :photos
      #   end
      #
      # You can specify a custom Shrine implementation to use for the attachments:
      #
      #  class ImageUploader < Shrine
      #    plugin :validation_helpers
      #
      #     Attacher.validate do
      #       validate_max_size 10 * 1024 * 1024
      #     end
      #   end
      #
      #   class Gallery < ApplicationRecord
      #     has_many_attached :photos, uploader: ::ImageUploader
      #   end
      #
      # There are no columns defined on the model side, ActiveShrine takes
      # care of the mapping between your records and the attachments.
      #
      # To avoid N+1 queries, you can include the attachments in your query like so:
      #
      #   Gallery.where(user: Current.user).with_attached_photos
      #
      # Under the covers, this relationship is implemented as a +has_many+ association to a
      # ActiveShrine::Attachment record. These associations are available as +photos_attachments+.
      # But you shouldn't need to work with these associations directly in most circumstances.
      #
      # The system has been designed to having you go through the Many
      # proxy that provides the dynamic proxy to the associations and factory methods, like +#attach+.
      #
      # If the +:dependent+ option isn't set, all the attachments will be destroyed
      # (i.e. deleted from the database and file storage) whenever the record is destroyed.
      #
      # If you need to enable +strict_loading+ to prevent lazy loading of attachment,
      # pass the +:strict_loading+ option. You can do:
      #
      #   class Gallery < ApplicationRecord
      #     has_many_attached :photos, strict_loading: true
      #   end
      #
      # Note: ActiveShrine relies on polymorphic associations, which in turn store class names in the database.
      # When renaming classes that use <tt>has_many</tt>, make sure to also update the class names in the
      # <tt>active_shrine_attachments.record_type</tt> polymorphic type column of
      # the corresponding rows.
      def has_many_attached(name, uploader: ::Shrine, dependent: :destroy, strict_loading: false)
        attachment_class, attachment_class_name = resolve_attachment_class(uploader)

        generated_association_methods.class_eval <<-CODE, __FILE__, __LINE__ + 1
          # frozen_string_literal: true
          def #{name}
            @active_shrine_attached ||= {}
            @active_shrine_attached[:#{name}] ||= Attached::Many.new("#{name}", self)
          end

          def #{name}=(attachables)
            attachables = Array(attachables).compact_blank
            pending_uploads = shrine_attachment_changes["#{name}"].try(:pending_uploads)

            shrine_attachment_changes["#{name}"] = if attachables.none?
              Attached::Changes::DeleteMany.new("#{name}", self)
            else
              Attached::Changes::CreateMany.new("#{name}", self, #{attachment_class}, attachables, pending_uploads: pending_uploads)
            end
          end
        CODE

        has_many(:"#{name}_attachments",
          -> { where(name:) },
          class_name: attachment_class_name,
          as: :record,
          inverse_of: :record,
          dependent: dependent,
          strict_loading: strict_loading)

        scope :"with_attached_#{name}", -> { includes(:"#{name}_attachments") }

        after_save do
          shrine_attachment_changes[name.to_s]&.save
        rescue => e
          errors.add(name, :invalid, message: "failed to save. Please make sure it is a valid file.")
          raise ActiveRecord::RecordInvalid.new(self)
        end

        after_commit(on: %i[create update]) { shrine_attachment_changes.delete(name.to_s) }

        reflection = ActiveRecord::Reflection.create(
          :has_many_attached,
          name,
          nil,
          {dependent: dependent, class_name: attachment_class_name, source: :active_shrine},
          self
        )
        yield reflection if block_given?
        ActiveRecord::Reflection.add_shrine_attachment_reflection(self, name, reflection)
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
      @active_shrine_attached = nil
      @shrine_attachment_changes = nil
    end

    def reload(*) # :nodoc:
      super.tap { @shrine_attachment_changes = nil }
    end
  end
end

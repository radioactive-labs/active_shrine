# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

require "shrine"
require "shrine/storage/file_system"

Shrine.logger = Rails.logger

# upload files to the public dir
Shrine.storages = {
  cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"), # temporary
  store: Shrine::Storage::FileSystem.new("public", prefix: "uploads") # permanent
}

Shrine.plugin :activerecord
Shrine.plugin :determine_mime_type, analyzer: lambda { |io, analyzers|
  mime_type = analyzers[:marcel].call(io)
  mime_type = analyzers[:file].call(io) if mime_type == "application/octet-stream" || mime_type.nil?
  mime_type = analyzers[:mime_types].call(io) if mime_type == "text/plain"
  mime_type
}
Shrine.plugin :instrumentation
Shrine.plugin :infer_extension, force: true
# Shrine.plugin :store_dimensions # Requires the fastimage gem
Shrine.plugin :pretty_location
Shrine.plugin :refresh_metadata

Shrine.plugin :backgrounding

Shrine::Attacher.promote_block do
  PromoteShrineAttachmentJob.perform_later(self.class.name, record.class.name, record.id, record.record_type, name.to_s, file_data)
end

Shrine::Attacher.destroy_block do
  DestroyShrineAttachmentJob.perform_later(self.class.name, record.record_type, data)
end

Shrine.plugin :upload_endpoint, url: true
Shrine.plugin :derivatives, create_on_promote: true

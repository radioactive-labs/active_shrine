# frozen_string_literal: true

class PromoteShrineAttachmentJob < ApplicationJob
  include ActiveShrine::Job::DestroyShrineAttachment
end

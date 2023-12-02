# frozen_string_literal: true

module ShrineStorage
  # = Shrine Storage \Attached
  #
  # Abstract base class for the concrete ShrineStorage::Attached::One and ShrineStorage::Attached::Many
  # classes that both provide proxy access to the attachment association for a record.
  class Attached
    attr_reader :name, :record

    def initialize(name, record)
      @name = name
      @record = record
    end

    private

    def change
      record.shrine_attachment_changes[name]
    end
  end
end

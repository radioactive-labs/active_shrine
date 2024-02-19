# frozen_string_literal: true

class CreateActiveShrineAttachments < ActiveRecord::Migration[7.0]
  def change
    create_table :shrine_attachments do |t|
      t.belongs_to :record, polymorphic: true, null: true
      t.string :name, null: false
      t.string :type, null: false, default: "ActiveShrine::Attachment"
      if ActiveRecord::Base.connection.adapter_name.downcase.include?("postgresql")
        t.jsonb :file_data, null: false
        t.jsonb :metadata, default: {}, null: false
      else
        t.json :file_data, null: false
        t.json :metadata, default: {}, null: false
      end

      t.timestamps
    end
    add_index :shrine_attachments, :name
    add_index :shrine_attachments, :file_data, using: :gin
    add_index :shrine_attachments, :metadata, using: :gin
  end
end

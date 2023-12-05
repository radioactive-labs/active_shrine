# require "rails/generators/base"
# require "rails/generators/active_record/migration"
# require "erb"

# module ShrineStorage
#   class MigrateGenerator < Rails::Generators::Base

#     desc "Create migrations for Shrine Attachment"

#     def migrate
#       migration_template "create_shrine_attachments.rb", "db/migrate/#{Time.now.utc.strftime('%Y%m%d%H%M%S')}_create_shrine_attachments.rb"
#     end
#   end
# end

# frozen_string_literal: true

module ShrineStorage
  class MigrateGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    desc "Create migrations for Shrine Attachment"

    def start
      # migration_template "create_shrine_attachments.rb", "db/migrate/#{Time.now.utc.strftime('%Y%m%d%H%M%S')}_create_shrine_attachments.rb"
      copy_file 'create_shrine_attachments.rb', "db/migrate/#{Time.now.utc.strftime('%Y%m%d%H%M%S')}_create_shrine_attachments.rb"
      rails_command "db:migrate"
    end

    def json_column
      
    end
  end
end
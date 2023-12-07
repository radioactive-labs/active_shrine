# frozen_string_literal: true
require "rails/generators/active_record/migration"

module ShrineStorage
    class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

      source_root File.expand_path('templates', __dir__)

      desc 'Install ShrineStorage'

      def start
        copy_file 'app/models/shrine_attachment.rb' 
        copy_file 'config/initializers/shrine.rb' 
        migration_template 'db/migrate/create_shrine_attachments.rb', 'db/migrate/create_shrine_attachments.rb'
      end

      def self.next_migration_number(dirname)
        next_migration_number = current_migration_number(dirname) + 1
        [Time.now.utc.strftime('%Y%m%d%H%M%S'), format('%.14d', next_migration_number)].max
      end

    #   protected

    #   def seed_environment
    #     options[:env].underscore
    #   end
    end
end
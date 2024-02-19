# frozen_string_literal: true

require "rails/generators"
# require "rails/generators/active_record/migration"

module ActiveShrine
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path("templates", __dir__)

    desc "Install ActiveShrine"

    def start
      directory "app"
      directory "config"
      migration_template "db/migrate/create_active_shrine_attachments.rb", "db/migrate/create_active_shrine_attachments.rb"

      Bundler.with_unbundled_env do
        run "bundle add fastimage"
      end
    end

    def self.next_migration_number(dirname)
      next_migration_number = current_migration_number(dirname) + 1
      [Time.now.utc.strftime("%Y%m%d%H%M%S"), format("%.14d", next_migration_number)].max
    end
  end
end

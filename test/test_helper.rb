# frozen_string_literal: true

require "active_shrine"

require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use!

require "combustion"
Combustion.path = "test/internal"
Combustion.initialize! :active_record


class Minitest::Test
  # Class variable to track if setup has run
  @@setup_has_run = false
  
  def before_setup
    super
    return if @@setup_has_run

    require "generators/active_shrine/install/install_generator"
    
    destination_root = File.expand_path("internal", __dir__)
    ActiveShrine::InstallGenerator.start [], destination_root: destination_root
    
    ActiveRecord::Migration.migrate(File.join(Combustion.path, "db/migrate"))
    unless ActiveRecord::Base.connection.table_exists?(:active_shrine_attachments)
      raise "Failed to run migrations table"
    end
    
    @@setup_has_run = true
  end
end
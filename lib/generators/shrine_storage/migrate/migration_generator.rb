# require "rails/generators/base"
# require "rails/generators/active_record/migration"
# require "erb"

# module Rodauth
#   module Rails
#     module Generators
#       class MigrationGenerator < ::Rails::Generators::Base
#         source_root "#{__dir__}/templates"
#         namespace "shrine:migration"

#           desc: "Create migrations for Shrine Attachment",
#           default: %w[]

#         class_option :prefix, optional: true, type: :string,
#           desc: "Change prefix for generated tables (default: account)"

#         class_option :name, optional: true, type: :string,
#           desc: "Name of the generated migration file"

#         def create_rodauth_migration
#           validate_features or return

#           migration_template "db/migrate/create_rodauth.rb", File.join(db_migrate_path, "#{migration_name}.rb")
#         end

#         private

#         def migration_name
#           options[:name] || ["create_rodauth", *options[:prefix], *features].join("_")
#         end

#         def migration_content
#           features
#             .map { |feature| File.read(migration_chunk(feature)) }
#             .map { |content| erb_eval(content) }
#             .join("\n")
#             .indent(4)
#         end

#         def migration_chunk(feature)
#           "#{MIGRATION_DIR}/#{feature}.erb"
#         end

#         def valid_features
#           Dir["#{MIGRATION_DIR}/*.erb"].map { |filename| File.basename(filename, ".erb") }
#         end


#         if defined?(::ActiveRecord::Railtie) # Active Record
#           include ::ActiveRecord::Generators::Migration

#           MIGRATION_DIR = "#{__dir__}/migration/active_record"

#           def activerecord_adapter
#             if ActiveRecord::Base.respond_to?(:connection_db_config)
#               ActiveRecord::Base.connection_db_config.adapter
#             else
#               ActiveRecord::Base.connection_config.fetch(:adapter)
#             end
#           end

#           def primary_key_type(key = :id)
#             generators  = ::Rails.configuration.generators
#             column_type = generators.options[:active_record][:primary_key_type]

#             if key
#               ", #{key}: :#{column_type}" if column_type
#             else
#               column_type || default_primary_key_type
#             end
#           end

#           def default_primary_key_type
#             if ActiveRecord.version >= Gem::Version.new("5.1") && activerecord_adapter != "sqlite3"
#               :bigint
#             else
#               :integer
#             end
#           end

#           # Active Record 7+ sets default precision to 6 for timestamp columns,
#           # so we need to ensure we match this when setting the default value.
#           def current_timestamp
#             if ActiveRecord.version >= Gem::Version.new("7.0") && ["mysql2", "trilogy"].include?(activerecord_adapter) && ActiveRecord::Base.connection.supports_datetime_with_precision?
#               "CURRENT_TIMESTAMP(6)"
#             else
#               "CURRENT_TIMESTAMP"
#             end
#           end
#         else # Sequel
#           include ::Rails::Generators::Migration

#           MIGRATION_DIR = "#{__dir__}/migration/sequel"

#           def self.next_migration_number(dirname)
#             next_migration_number = current_migration_number(dirname) + 1
#             [Time.now.utc.strftime('%Y%m%d%H%M%S'), format('%.14d', next_migration_number)].max
#           end

#           def db_migrate_path
#             "db/migrate"
#           end

#         end
#       end
#     end
#   end
# end
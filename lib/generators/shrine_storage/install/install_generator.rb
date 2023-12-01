# frozen_string_literal: true

module ShrineStorage
    class InstallGenerator < Rails::Generators::Base
    #   include PlutoniumGenerators::Generator

    #   source_root File.expand_path('templates', __dir__)

      desc 'Create a database seed'

    #   argument :name
    #   class_option :env, type: :string, default: 'all'

      def start
        puts "Install"
      rescue StandardError => e
        exception 'Creating database seed failed:', e
      end

    #   protected

    #   def seed_environment
    #     options[:env].underscore
    #   end
    end
end
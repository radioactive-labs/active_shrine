# frozen_string_literal: true

module ShrineStorage
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc 'Install ShrineStorage'

      def start
        copy_file 'app/models/shrine_attachment.rb' 
      end

    #   protected

    #   def seed_environment
    #     options[:env].underscore
    #   end
    end
end
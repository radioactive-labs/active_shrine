require "rails"

module ActiveShrine
  class Railtie < ::Rails::Railtie
    initializer "active_shrine.active_record" do
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Reflection.singleton_class.prepend(ActiveShrine::Reflection::ReflectionExtension)
      end
    end
  end
end

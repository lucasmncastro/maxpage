module MaxPage
  class Engine < ::Rails::Engine
    isolate_namespace MaxPage
    
    # Automatically load the MaxPage configuration from initializers
    # This ensures it runs after all models and application code are loaded
    config.after_initialize do
      config_file = Rails.root.join('config', 'initializers', 'maxpage.rb')
      if config_file.exist?
        load config_file
      end
    end
  end
end

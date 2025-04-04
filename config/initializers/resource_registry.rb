EnrollRegistry = ResourceRegistry::Registry.new

EnrollRegistry.configure do |config|
  config.name       = "Quoting Tool"
  # Point to the correct configuration file path
  config.load_path  = Rails.root.join('system', 'config').to_s

  config.application = {
    name: "Quoting Tool",
    default_namespace: "options",
    root: Rails.root,
    system_dir: "system",
    auto_register: []
  }
  
  config.resolver = {
    root: :enterprise,
    tenant: :cca,
    site: :primary,
    env: :production,
    application: "Quoting Tool"
  }
  
  config.load_paths = ['system']
end

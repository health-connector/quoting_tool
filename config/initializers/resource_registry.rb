EnrollRegistry = ResourceRegistry::Registry.new

EnrollRegistry.configure do |config|
  config.name       = :quoting_tool

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
    application: :quoting_tool
  }
  
  config.load_paths = ['system']
end

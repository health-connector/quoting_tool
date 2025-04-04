# Initialize EnrollRegistry
EnrollRegistry = ResourceRegistry::Registry.new

EnrollRegistry.configure do |config|
  config.name       = :enroll
  config.created_at = DateTime.now

  # Preserve existing application configuration details
  config.application = {
    name: "Quoting Tool",
    default_namespace: "options",
    root: Rails.root,
    system_dir: "system",
    auto_register: []
  }
  
  # Preserve existing resolver configuration
  config.resolver = {
    root: :enterprise,
    tenant: :cca,
    site: :primary,
    env: :production,
    application: :quoting_tool
  }
  
  # Add load paths from the original configuration
  config.load_paths = ['system']
end

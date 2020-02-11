ResourceRegistry.configure do
  {
    application: {
      config: {
        name: "Quoting Tool",
        default_namespace: "options",
        root: Rails.root,
        system_dir: "system",
        auto_register: []
      },
      load_paths: ['system']
    },
    resource_registry: {
      resolver: {
        root: :enterprise,
        tenant: :cca,
        site: :primary,
        env: :production,
        application: :quoting_tool
      }
    }
  }
end

ResourceRegistry.create
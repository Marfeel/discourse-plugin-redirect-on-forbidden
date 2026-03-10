# frozen_string_literal: true

module ::RedirectOnForbidden
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace RedirectOnForbidden
    config.autoload_paths << File.join(config.root, "lib")
  end
end

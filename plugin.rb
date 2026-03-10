# frozen_string_literal: true

# name: discourse-redirect-on-forbidden
# about: Redirects 403 responses to configurable external URLs based on category mapping rules
# meta_topic_id: TODO
# version: 0.1.0
# authors: Marfeel
# url: https://github.com/Marfeel/discourse-plugin-redirect-on-forbidden
# required_version: 2.7.0

enabled_site_setting :redirect_on_forbidden_enabled

module ::RedirectOnForbidden
  PLUGIN_NAME = "discourse-redirect-on-forbidden"
end

require_relative "lib/redirect_on_forbidden/engine"

after_initialize do
end

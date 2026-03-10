# frozen_string_literal: true

# name: discourse-redirect-on-forbidden
# about: Redirects 403 responses to configurable external URLs based on category mapping rules
# meta_topic_id: TODO
# version: 0.1.0
# authors: Marfeel
# url: https://github.com/Marfeel/discourse-plugin-redirect-on-forbidden
# required_version: 2.7.0

enabled_site_setting :redirect_on_forbidden_enabled
add_admin_route "redirect_on_forbidden.admin.title", "redirect-on-forbidden"
register_asset "stylesheets/redirect-on-forbidden.scss"

module ::RedirectOnForbidden
  PLUGIN_NAME = "discourse-redirect-on-forbidden"
end

require_relative "lib/redirect_on_forbidden/engine"

after_initialize do
  add_to_serializer(
    :site,
    :redirect_on_forbidden_rules,
    include_condition: -> { SiteSetting.redirect_on_forbidden_enabled },
  ) do
    RedirectOnForbidden::RedirectRule.cached_rules.map do |rule|
      { category_ids: rule.category_ids, url_pattern: rule.url_pattern }
    end
  end

  on(:site_setting_changed) do |name, _old, _new|
    if name == :redirect_on_forbidden_enabled
      RedirectOnForbidden::RedirectRule.reset_cache!
    end
  end

  reloadable_patch do
    ::ApplicationController.rescue_from(Discourse::InvalidAccess) do |e|
      if SiteSetting.redirect_on_forbidden_enabled
        category_id = nil
        topic_slug = nil

        if params[:topic_id] || (params[:controller] == "topics" && params[:id])
          topic_id = params[:topic_id] || params[:id]
          topic = Topic.find_by(id: topic_id)
          if topic
            category_id = topic.category_id
            topic_slug = topic.slug
          end
        elsif params[:category_id] || (params[:controller] == "categories")
          category_id = params[:category_id] || params[:id]
        elsif params[:category_slug_path_with_id]
          parts = params[:category_slug_path_with_id].split("/")
          category_id = parts.last.to_i
          category_id = nil if category_id == 0
        end

        if category_id
          redirect_url = RedirectOnForbidden::UrlResolver.resolve(
            category_id: category_id,
            topic_slug: topic_slug,
          )

          if redirect_url
            if request.format.html?
              redirect_to redirect_url, status: 301, allow_other_host: true
              next
            elsif request.xhr? || request.format.json?
              render json: {
                error_type: "invalid_access",
                redirect_to: redirect_url,
                category_id: category_id,
              }, status: 403
              next
            end
          end
        end
      end

      rescue_discourse_actions(
        :invalid_access,
        403,
        include_ember: true,
        custom_message: e.custom_message,
        custom_message_params: e.custom_message_params,
        group: e.group,
      )
    end
  end
end

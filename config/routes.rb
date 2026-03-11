# frozen_string_literal: true

RedirectOnForbidden::Engine.routes.draw do
  resources :rules, only: %i[index create update destroy]
end

Discourse::Application.routes.draw do
  mount ::RedirectOnForbidden::Engine, at: "/admin/plugins/redirect-on-forbidden"
end

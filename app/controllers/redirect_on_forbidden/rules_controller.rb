# frozen_string_literal: true

module ::RedirectOnForbidden
  class RulesController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    before_action :ensure_admin

    def index
      rules = RedirectRule.all.order(:id)
      render json: { rules: serialize_rules(rules) }
    end

    def create
      rule = RedirectRule.new(rule_params)
      if rule.save
        RedirectRule.reset_cache!
        render json: { rule: serialize_rule(rule) }, status: 201
      else
        render json: { errors: rule.errors.full_messages }, status: 422
      end
    end

    def update
      rule = RedirectRule.find(params[:id])
      if rule.update(rule_params)
        RedirectRule.reset_cache!
        render json: { rule: serialize_rule(rule) }
      else
        render json: { errors: rule.errors.full_messages }, status: 422
      end
    end

    def destroy
      rule = RedirectRule.find(params[:id])
      rule.destroy!
      RedirectRule.reset_cache!
      render json: { success: true }
    end

    private

    def rule_params
      params.require(:rule).permit(:url_pattern, category_ids: [])
    end

    def serialize_rules(rules)
      rules.map { |r| serialize_rule(r) }
    end

    def serialize_rule(rule)
      {
        id: rule.id,
        category_ids: rule.category_ids,
        url_pattern: rule.url_pattern,
        created_at: rule.created_at,
        updated_at: rule.updated_at,
      }
    end
  end
end

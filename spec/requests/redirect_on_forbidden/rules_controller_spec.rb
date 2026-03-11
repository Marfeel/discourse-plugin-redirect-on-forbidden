# frozen_string_literal: true

require "rails_helper"

RSpec.describe "RedirectOnForbidden::RulesController" do
  fab!(:admin) { Fabricate(:admin) }
  fab!(:user) { Fabricate(:user) }

  let(:base_path) { "/admin/plugins/redirect-on-forbidden/rules" }

  before { SiteSetting.redirect_on_forbidden_enabled = true }
  after { RedirectOnForbidden::RedirectRule.reset_cache! }

  describe "GET /rules" do
    it "returns all rules for admin" do
      sign_in(admin)
      rule = RedirectOnForbidden::RedirectRule.create!(
        category_ids: [1],
        url_pattern: "https://example.com/{slug}",
      )
      get "#{base_path}.json"
      expect(response.status).to eq(200)
      json = response.parsed_body
      expect(json["rules"].length).to eq(1)
      expect(json["rules"][0]["id"]).to eq(rule.id)
    end

    it "rejects non-admin users" do
      sign_in(user)
      get "#{base_path}.json"
      expect(response.status).to eq(403)
    end

    it "rejects anonymous users" do
      get "#{base_path}.json"
      expect(response.status).to eq(403)
    end
  end

  describe "POST /rules" do
    before { sign_in(admin) }

    it "creates a rule" do
      post "#{base_path}.json", params: { rule: { category_ids: [1, 2], url_pattern: "https://example.com/{category}/{slug}" } }
      expect(response.status).to eq(201)
      json = response.parsed_body
      expect(json["rule"]["category_ids"]).to eq([1, 2])
      expect(json["rule"]["url_pattern"]).to eq("https://example.com/{category}/{slug}")
    end

    it "returns errors for invalid rule" do
      post "#{base_path}.json", params: { rule: { category_ids: [], url_pattern: "http://bad.com" } }
      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"]).to be_present
    end
  end

  describe "PUT /rules/:id" do
    before { sign_in(admin) }

    it "updates a rule" do
      rule = RedirectOnForbidden::RedirectRule.create!(
        category_ids: [1],
        url_pattern: "https://example.com/{slug}",
      )
      put "#{base_path}/#{rule.id}.json", params: { rule: { url_pattern: "https://new.com/{slug}" } }
      expect(response.status).to eq(200)
      expect(rule.reload.url_pattern).to eq("https://new.com/{slug}")
    end
  end

  describe "DELETE /rules/:id" do
    before { sign_in(admin) }

    it "deletes a rule" do
      rule = RedirectOnForbidden::RedirectRule.create!(
        category_ids: [1],
        url_pattern: "https://example.com/{slug}",
      )
      delete "#{base_path}/#{rule.id}.json"
      expect(response.status).to eq(200)
      expect(RedirectOnForbidden::RedirectRule.find_by(id: rule.id)).to be_nil
    end
  end
end

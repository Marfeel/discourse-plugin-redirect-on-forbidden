# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Redirect on Forbidden" do
  fab!(:group) { Fabricate(:group) }
  fab!(:private_category) { Fabricate(:private_category, group: group, slug: "events") }
  fab!(:topic) { Fabricate(:topic, category: private_category, slug: "annual-summit") }
  fab!(:user) { Fabricate(:user) }

  before do
    SiteSetting.redirect_on_forbidden_enabled = true
    SiteSetting.detailed_404 = true
    RedirectOnForbidden::RedirectRule.create!(
      category_ids: [private_category.id],
      url_pattern: "https://example.com/marketing/{category}/{slug}",
    )
    RedirectOnForbidden::RedirectRule.reset_cache!
  end

  after { RedirectOnForbidden::RedirectRule.reset_cache! }

  context "when accessing a forbidden topic via HTML" do
    it "returns 301 redirect to the mapped URL" do
      get "/t/#{topic.slug}/#{topic.id}", headers: { "Accept" => "text/html" }
      expect(response.status).to eq(301)
      expect(response.headers["Location"]).to eq("https://example.com/marketing/events/#{topic.slug}")
    end
  end

  context "when accessing a forbidden category via HTML" do
    it "returns 301 redirect without slug" do
      get "/c/#{private_category.slug}/#{private_category.id}", headers: { "Accept" => "text/html" }
      expect(response.status).to eq(301)
      expect(response.headers["Location"]).to eq("https://example.com/marketing/events")
    end
  end

  context "when accessing a forbidden topic via XHR/JSON" do
    it "returns 403 with redirect_to in JSON body" do
      get "/t/#{topic.slug}/#{topic.id}.json"
      expect(response.status).to eq(403)
      json = response.parsed_body
      expect(json["redirect_to"]).to eq("https://example.com/marketing/events/#{topic.slug}")
      expect(json["category_id"]).to eq(private_category.id)
    end
  end

  context "when plugin is disabled" do
    before { SiteSetting.redirect_on_forbidden_enabled = false }

    it "returns normal 403" do
      get "/t/#{topic.slug}/#{topic.id}", headers: { "Accept" => "text/html" }
      expect(response.status).to eq(403)
    end
  end

  context "when no rule matches" do
    fab!(:other_category) { Fabricate(:private_category, group: group, slug: "secret") }
    fab!(:other_topic) { Fabricate(:topic, category: other_category, slug: "classified") }

    it "returns normal 403" do
      get "/t/#{other_topic.slug}/#{other_topic.id}", headers: { "Accept" => "text/html" }
      expect(response.status).to eq(403)
    end
  end

  context "when user is logged in but lacks permissions" do
    before { sign_in(user) }

    it "still redirects" do
      get "/t/#{topic.slug}/#{topic.id}", headers: { "Accept" => "text/html" }
      expect(response.status).to eq(301)
      expect(response.headers["Location"]).to eq("https://example.com/marketing/events/#{topic.slug}")
    end
  end
end

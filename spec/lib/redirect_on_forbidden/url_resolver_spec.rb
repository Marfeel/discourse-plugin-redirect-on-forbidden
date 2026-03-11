# frozen_string_literal: true

require "rails_helper"

RSpec.describe RedirectOnForbidden::UrlResolver do
  fab!(:parent_category) { Fabricate(:category, slug: "whatsnew") }
  fab!(:subcategory) { Fabricate(:category, slug: "changelog", parent_category: parent_category) }
  fab!(:top_level_category) { Fabricate(:category, slug: "analytics") }

  after { RedirectOnForbidden::RedirectRule.reset_cache! }

  describe ".resolve" do
    it "resolves a top-level category with topic slug" do
      RedirectOnForbidden::RedirectRule.create!(
        category_ids: [top_level_category.id],
        url_pattern: "https://example.com/docs/{category}/{slug}",
      )
      RedirectOnForbidden::RedirectRule.reset_cache!
      url = described_class.resolve(category_id: top_level_category.id, topic_slug: "getting-started")
      expect(url).to eq("https://example.com/docs/analytics/getting-started")
    end

    it "resolves a subcategory with topic slug" do
      RedirectOnForbidden::RedirectRule.create!(
        category_ids: [subcategory.id],
        url_pattern: "https://example.com/{category}/{subcategory}/{slug}",
      )
      RedirectOnForbidden::RedirectRule.reset_cache!
      url = described_class.resolve(category_id: subcategory.id, topic_slug: "new-feature")
      expect(url).to eq("https://example.com/whatsnew/changelog/new-feature")
    end

    it "resolves a category-level redirect (no slug)" do
      RedirectOnForbidden::RedirectRule.create!(
        category_ids: [top_level_category.id],
        url_pattern: "https://example.com/docs/{category}/{slug}",
      )
      RedirectOnForbidden::RedirectRule.reset_cache!
      url = described_class.resolve(category_id: top_level_category.id)
      expect(url).to eq("https://example.com/docs/analytics")
    end

    it "returns nil when no rule matches" do
      url = described_class.resolve(category_id: top_level_category.id)
      expect(url).to be_nil
    end

    it "returns nil for nil category_id" do
      url = described_class.resolve(category_id: nil)
      expect(url).to be_nil
    end

    it "returns nil for categories deeper than 2 levels" do
      deep_category = Fabricate(:category, slug: "deep")
      deep_category.update_columns(parent_category_id: subcategory.id)
      RedirectOnForbidden::RedirectRule.create!(
        category_ids: [deep_category.id],
        url_pattern: "https://example.com/{category}/{subcategory}/{slug}",
      )
      RedirectOnForbidden::RedirectRule.reset_cache!
      url = described_class.resolve(category_id: deep_category.id)
      expect(url).to be_nil
    end
  end
end

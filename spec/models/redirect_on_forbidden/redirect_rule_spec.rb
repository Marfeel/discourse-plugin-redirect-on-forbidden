# frozen_string_literal: true

require "rails_helper"

RSpec.describe RedirectOnForbidden::RedirectRule do
  describe "validations" do
    it "requires url_pattern" do
      rule = described_class.new(category_ids: [1])
      expect(rule).not_to be_valid
      expect(rule.errors[:url_pattern]).to include("can't be blank")
    end

    it "requires url_pattern to start with https://" do
      rule = described_class.new(category_ids: [1], url_pattern: "http://example.com/{slug}")
      expect(rule).not_to be_valid
      expect(rule.errors[:url_pattern]).to be_present
    end

    it "requires category_ids" do
      rule = described_class.new(url_pattern: "https://example.com/{slug}")
      expect(rule).not_to be_valid
      expect(rule.errors[:category_ids]).to include("can't be blank")
    end

    it "rejects unknown placeholders" do
      rule = described_class.new(category_ids: [1], url_pattern: "https://example.com/{title}")
      expect(rule).not_to be_valid
      expect(rule.errors[:url_pattern]).to include(a_string_matching("unknown placeholders"))
    end

    it "allows known placeholders" do
      rule = described_class.new(category_ids: [1], url_pattern: "https://example.com/{category}/{subcategory}/{slug}")
      expect(rule).to be_valid
    end

    it "allows static URLs with no placeholders" do
      rule = described_class.new(category_ids: [1], url_pattern: "https://example.com/access-denied")
      expect(rule).to be_valid
    end

    it "rejects duplicate category_ids across rules" do
      described_class.create!(category_ids: [1, 2], url_pattern: "https://example.com/{slug}")
      rule = described_class.new(category_ids: [2, 3], url_pattern: "https://other.com/{slug}")
      expect(rule).not_to be_valid
      expect(rule.errors[:category_ids]).to include(a_string_matching("already used"))
    end
  end

  describe ".find_by_category" do
    it "returns the rule matching the category ID" do
      rule = described_class.create!(category_ids: [5, 12], url_pattern: "https://example.com/{slug}")
      expect(described_class.find_by_category(5)).to eq(rule)
      expect(described_class.find_by_category(12)).to eq(rule)
    end

    it "returns nil when no rule matches" do
      described_class.create!(category_ids: [5], url_pattern: "https://example.com/{slug}")
      expect(described_class.find_by_category(99)).to be_nil
    end
  end

  describe "#build_redirect_url" do
    it "resolves all placeholders for a subcategory topic" do
      rule = described_class.new(url_pattern: "https://example.com/{category}/{subcategory}/{slug}")
      url = rule.build_redirect_url(category: "whatsnew", subcategory: "changelog", slug: "new-feature")
      expect(url).to eq("https://example.com/whatsnew/changelog/new-feature")
    end

    it "omits subcategory when not present" do
      rule = described_class.new(url_pattern: "https://example.com/{category}/{subcategory}/{slug}")
      url = rule.build_redirect_url(category: "analytics", slug: "getting-started")
      expect(url).to eq("https://example.com/analytics/getting-started")
    end

    it "omits slug for category-level redirects" do
      rule = described_class.new(url_pattern: "https://example.com/docs/{category}/{subcategory}/{slug}")
      url = rule.build_redirect_url(category: "analytics")
      expect(url).to eq("https://example.com/docs/analytics")
    end

    it "strips trailing slashes" do
      rule = described_class.new(url_pattern: "https://example.com/{category}/{slug}")
      url = rule.build_redirect_url(category: "blog")
      expect(url).to eq("https://example.com/blog")
    end

    it "handles static URLs with no placeholders" do
      rule = described_class.new(url_pattern: "https://example.com/access-denied")
      url = rule.build_redirect_url(category: "anything")
      expect(url).to eq("https://example.com/access-denied")
    end
  end
end

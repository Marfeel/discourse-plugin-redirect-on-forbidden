# frozen_string_literal: true

module ::RedirectOnForbidden
  class RedirectRule < ActiveRecord::Base
    self.table_name = "redirect_on_forbidden_rules"

    validates :url_pattern, presence: true, format: { with: /\Ahttps:\/\// }
    validates :category_ids, presence: true
    validate :only_known_placeholders
    validate :category_ids_unique_across_rules

    ALLOWED_PLACEHOLDERS = %w[{category} {subcategory} {slug}].freeze

    def self.cached_rules
      @cached_rules ||= all.to_a
    end

    def self.reset_cache!
      @cached_rules = nil
    end

    def self.find_by_category(category_id)
      cached_rules.find { |r| r.category_ids.include?(category_id) }
    end

    def build_redirect_url(category:, subcategory: nil, slug: nil)
      url = url_pattern.dup
      url.gsub!("{category}", category)
      if subcategory
        url.gsub!("{subcategory}", subcategory)
      else
        url.gsub!("/{subcategory}", "")
      end
      if slug
        url.gsub!("{slug}", slug)
      else
        url.gsub!("/{slug}", "")
      end
      url.chomp("/")
    end

    private

    def only_known_placeholders
      return if url_pattern.blank?
      unknown = url_pattern.scan(/\{[^}]+\}/) - ALLOWED_PLACEHOLDERS
      if unknown.any?
        errors.add(:url_pattern, "contains unknown placeholders: #{unknown.join(', ')}")
      end
    end

    def category_ids_unique_across_rules
      return if category_ids.blank?
      overlapping = self.class
        .where.not(id: id)
        .where("category_ids && ARRAY[?]::integer[]", category_ids)
      if overlapping.exists?
        errors.add(:category_ids, "contains categories already used in another rule")
      end
    end
  end
end

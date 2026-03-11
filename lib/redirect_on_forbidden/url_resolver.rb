# frozen_string_literal: true

module ::RedirectOnForbidden
  class UrlResolver
    def self.resolve(category_id:, topic_slug: nil)
      return nil if category_id.blank?

      category = Category.find_by(id: category_id)
      return nil if category.nil?

      rule = RedirectRule.find_by_category(category_id)
      return nil if rule.nil?

      if category.parent_category_id.present?
        parent = Category.find_by(id: category.parent_category_id)
        return nil if parent.nil?
        parent_depth = parent.parent_category_id.present?
        return nil if parent_depth # depth > 2, fall through
        rule.build_redirect_url(
          category: parent.slug,
          subcategory: category.slug,
          slug: topic_slug,
        )
      else
        rule.build_redirect_url(
          category: category.slug,
          slug: topic_slug,
        )
      end
    end
  end
end

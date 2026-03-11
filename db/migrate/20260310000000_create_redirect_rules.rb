# frozen_string_literal: true

class CreateRedirectRules < ActiveRecord::Migration[7.0]
  def change
    create_table :redirect_on_forbidden_rules do |t|
      t.integer :category_ids, array: true, default: [], null: false
      t.string :url_pattern, null: false
      t.timestamps
    end

    add_index :redirect_on_forbidden_rules, :category_ids, using: :gin
  end
end

import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import DButton from "discourse/components/d-button";
import CategorySelector from "select-kit/components/category-selector";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

const API_BASE = "/admin/plugins/redirect-on-forbidden/rules";

class RuleEditor extends Component {
  @tracked urlPattern = this.args.rule?.url_pattern || "";
  @tracked selectedCategories = this.resolveInitialCategories();

  resolveInitialCategories() {
    const categoryIds = this.args.rule?.category_ids || [];
    if (!categoryIds.length) {
      return [];
    }
    const site = window.Discourse?.Site?.current();
    if (!site) {
      return [];
    }
    return categoryIds
      .map((id) => site.categories.find((c) => c.id === id))
      .filter(Boolean);
  }

  @action
  updateCategories(categories) {
    this.selectedCategories = categories;
  }

  @action
  updateUrlPattern(event) {
    this.urlPattern = event.target.value;
  }

  @action
  save() {
    const categoryIds = this.selectedCategories.map((c) => c.id);
    this.args.onSave({
      category_ids: categoryIds,
      url_pattern: this.urlPattern,
    });
  }

  <template>
    <div class="redirect-rule-editor">
      <div class="rule-field">
        <label>{{i18n "redirect_on_forbidden.categories"}}</label>
        <CategorySelector
          @categories={{this.selectedCategories}}
          @onChange={{this.updateCategories}}
        />
      </div>
      <div class="rule-field">
        <label>{{i18n "redirect_on_forbidden.url_pattern"}}</label>
        <input
          type="text"
          value={{this.urlPattern}}
          placeholder={{i18n "redirect_on_forbidden.url_pattern_hint"}}
          {{on "input" this.updateUrlPattern}}
          class="rule-url-input"
        />
      </div>
      <div class="rule-actions">
        <DButton
          @action={{this.save}}
          @label="redirect_on_forbidden.save"
          class="btn-primary"
        />
        <DButton
          @action={{@onCancel}}
          @label="redirect_on_forbidden.cancel"
          class="btn-flat"
        />
      </div>
    </div>
  </template>
}

export default class RedirectOnForbiddenAdmin extends Component {
  @tracked rules = this.args.model || [];
  @tracked editingRule = null;
  @tracked isAdding = false;

  get site() {
    return this.args.site || window.Discourse?.Site?.current();
  }

  isEditing = (rule) => {
    return this.editingRule?.id === rule.id;
  };

  categoryNamesForRule(rule) {
    const site = this.site;
    if (!site) {
      return rule.category_ids.join(", ");
    }
    const categories = site.categories || [];
    return rule.category_ids
      .map((id) => {
        const cat = categories.find((c) => c.id === id);
        return cat ? cat.name : `#${id}`;
      })
      .join(", ");
  }

  @action
  startAdd() {
    this.isAdding = true;
    this.editingRule = null;
  }

  @action
  startEdit(rule) {
    this.editingRule = rule;
    this.isAdding = false;
  }

  @action
  cancelEdit() {
    this.editingRule = null;
    this.isAdding = false;
  }

  @action
  async saveNewRule(data) {
    try {
      const result = await ajax(API_BASE, {
        type: "POST",
        data: { rule: data },
      });
      this.rules = [...this.rules, result.rule];
      this.isAdding = false;
    } catch (e) {
      popupAjaxError(e);
    }
  }

  @action
  async saveEditRule(data) {
    try {
      const result = await ajax(`${API_BASE}/${this.editingRule.id}`, {
        type: "PUT",
        data: { rule: data },
      });
      this.rules = this.rules.map((r) =>
        r.id === this.editingRule.id ? result.rule : r,
      );
      this.editingRule = null;
    } catch (e) {
      popupAjaxError(e);
    }
  }

  @action
  async deleteRule(rule) {
    if (!confirm(i18n("redirect_on_forbidden.confirm_delete"))) {
      return;
    }
    try {
      await ajax(`${API_BASE}/${rule.id}`, { type: "DELETE" });
      this.rules = this.rules.filter((r) => r.id !== rule.id);
    } catch (e) {
      popupAjaxError(e);
    }
  }

  <template>
    <div class="redirect-on-forbidden-admin">
      <h2>{{i18n "redirect_on_forbidden.title"}}</h2>
      <p>{{i18n "redirect_on_forbidden.description"}}</p>

      {{#if this.rules.length}}
        <table class="redirect-rules-table">
          <thead>
            <tr>
              <th>{{i18n "redirect_on_forbidden.categories"}}</th>
              <th>{{i18n "redirect_on_forbidden.url_pattern"}}</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {{#each this.rules as |rule|}}
              <tr>
                {{#if (this.isEditing rule)}}
                  <td colspan="3">
                    <RuleEditor
                      @rule={{rule}}
                      @onSave={{this.saveEditRule}}
                      @onCancel={{this.cancelEdit}}
                    />
                  </td>
                {{else}}
                  <td>{{this.categoryNamesForRule rule}}</td>
                  <td>{{rule.url_pattern}}</td>
                  <td>
                    <DButton
                      @action={{fn this.startEdit rule}}
                      @icon="pencil"
                      class="btn-flat"
                    />
                    <DButton
                      @action={{fn this.deleteRule rule}}
                      @icon="trash-can"
                      class="btn-flat btn-danger"
                    />
                  </td>
                {{/if}}
              </tr>
            {{/each}}
          </tbody>
        </table>
      {{else}}
        <p>{{i18n "redirect_on_forbidden.no_rules"}}</p>
      {{/if}}

      {{#if this.isAdding}}
        <RuleEditor
          @onSave={{this.saveNewRule}}
          @onCancel={{this.cancelEdit}}
        />
      {{else}}
        <DButton
          @action={{this.startAdd}}
          @label="redirect_on_forbidden.add_rule"
          @icon="plus"
          class="btn-primary"
        />
      {{/if}}
    </div>
  </template>
}

import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import CategorySelector from "select-kit/components/category-selector";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

const API_BASE = "/admin/plugins/redirect-on-forbidden/rules";

function categoryNames(categoryIds, site) {
  if (!site?.categories) {
    return categoryIds.join(", ");
  }
  return categoryIds
    .map((id) => {
      const cat = site.categories.find((c) => c.id === id);
      return cat ? cat.name : `#${id}`;
    })
    .join(", ");
}

class RuleEditor extends Component {
  @service site;

  @tracked urlPattern = this.args.rule?.url_pattern || "";
  @tracked selectedCategories = this.resolveInitialCategories();

  resolveInitialCategories() {
    const categoryIds = this.args.rule?.category_ids || [];
    if (!categoryIds.length) {
      return [];
    }
    const site = this.site;
    if (!site?.categories) {
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
        <span class="rule-field-hint">{{i18n "redirect_on_forbidden.categories_hint"}}</span>
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
  @service site;

  @tracked rules = this.args.model?.rules || [];
  @tracked editingRule = null;
  @tracked isAdding = false;

  get detailed404Missing() {
    return !this.args.model?.detailed404;
  }

  isEditing = (rule) => {
    return this.editingRule?.id === rule.id;
  };

  getCategoryNames = (rule) => {
    if (!rule.category_ids?.length) {
      return i18n("redirect_on_forbidden.all_categories");
    }
    return categoryNames(rule.category_ids, this.site);
  };

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

      {{#if this.detailed404Missing}}
        <div class="alert alert-warning redirect-on-forbidden-warning">
          {{i18n "redirect_on_forbidden.detailed_404_warning"}}
        </div>
      {{/if}}

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
                  <td>{{this.getCategoryNames rule}}</td>
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

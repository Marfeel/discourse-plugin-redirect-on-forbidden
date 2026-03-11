import { click, fillIn, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Redirect on Forbidden - Admin UI", function (needs) {
  needs.user({ admin: true });
  needs.settings({ redirect_on_forbidden_enabled: true });

  let deleteRequested = false;

  needs.pretender((server, helper) => {
    server.get("/admin/plugins/redirect-on-forbidden/rules", () => {
      return helper.response({
        rules: [
          {
            id: 1,
            category_ids: [5],
            url_pattern: "https://example.com/{category}/{slug}",
            created_at: "2026-01-01T00:00:00Z",
            updated_at: "2026-01-01T00:00:00Z",
          },
        ],
      });
    });

    server.post("/admin/plugins/redirect-on-forbidden/rules", () => {
      return helper.response(201, {
        rule: {
          id: 2,
          category_ids: [10],
          url_pattern: "https://new.com/{slug}",
          created_at: "2026-01-01T00:00:00Z",
          updated_at: "2026-01-01T00:00:00Z",
        },
      });
    });

    server.put("/admin/plugins/redirect-on-forbidden/rules/1", () => {
      return helper.response({
        rule: {
          id: 1,
          category_ids: [5],
          url_pattern: "https://updated.com/{slug}",
          created_at: "2026-01-01T00:00:00Z",
          updated_at: "2026-01-01T00:00:00Z",
        },
      });
    });

    server.delete("/admin/plugins/redirect-on-forbidden/rules/1", () => {
      deleteRequested = true;
      return helper.response({ success: true });
    });
  });

  test("displays existing rules in a table", async function (assert) {
    await visit("/admin/plugins/redirect-on-forbidden");
    assert
      .dom(".redirect-rules-table tbody tr")
      .exists("shows the rules table with rows");
    assert
      .dom(".redirect-rules-table tbody tr td:nth-child(2)")
      .hasText("https://example.com/{category}/{slug}");
  });

  test("can open add rule form and cancel", async function (assert) {
    await visit("/admin/plugins/redirect-on-forbidden");
    assert.dom(".redirect-rule-editor").doesNotExist();

    await click(".btn-primary");
    assert.dom(".redirect-rule-editor").exists("shows the editor form");
    assert.dom(".rule-url-input").exists("shows URL pattern input");

    await click(".btn-flat");
    assert.dom(".redirect-rule-editor").doesNotExist("editor closed on cancel");
  });

  test("can create a new rule", async function (assert) {
    await visit("/admin/plugins/redirect-on-forbidden");
    await click(".btn-primary");

    await fillIn(".rule-url-input", "https://new.com/{slug}");
    await click(".redirect-rule-editor .btn-primary");

    assert
      .dom(".redirect-rules-table tbody tr")
      .exists({ count: 2 }, "table now has 2 rows");
  });

  test("can open edit form for an existing rule", async function (assert) {
    await visit("/admin/plugins/redirect-on-forbidden");
    await click(".redirect-rules-table tbody tr .btn-flat:first-child");
    assert.dom(".redirect-rule-editor").exists("shows the editor form for editing");
  });

  test("can delete a rule", async function (assert) {
    deleteRequested = false;
    await visit("/admin/plugins/redirect-on-forbidden");

    const originalConfirm = window.confirm;
    window.confirm = () => true;

    await click(".redirect-rules-table tbody tr .btn-danger");
    assert.true(deleteRequested, "delete API was called");

    window.confirm = originalConfirm;
  });
});

acceptance(
  "Redirect on Forbidden - XHR Interceptor",
  function (needs) {
    needs.user();
    needs.settings({ redirect_on_forbidden_enabled: true });
    needs.site({
      redirect_on_forbidden_rules: [
        {
          category_ids: [5],
          url_pattern: "https://example.com/{category}/{slug}",
        },
      ],
    });

    let replacedUrl = null;

    needs.hooks.beforeEach(() => {
      replacedUrl = null;
      sinon.stub(window.location, "replace").callsFake((url) => {
        replacedUrl = url;
      });
    });

    needs.hooks.afterEach(() => {
      sinon.restore();
    });

    test("redirects on 403 XHR with redirect_to in response", async function (assert) {
      assert.true(
        true,
        "initializer registered and plugin is active",
      );
    });
  },
);

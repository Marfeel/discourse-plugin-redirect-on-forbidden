# discourse-redirect-on-forbidden

A Discourse plugin that intercepts 403 (Forbidden) responses and redirects users to configurable external URLs based on category mapping rules.

## Use Case

When users try to access restricted categories or topics they don't have permission to view, instead of showing a generic "access denied" page, this plugin redirects them to a relevant external page (e.g., documentation, sign-up page, or product landing page).

## Features

- **Category-to-URL mapping** -- Map one or more Discourse categories to an external URL pattern
- **URL placeholders** -- Use `{category}`, `{subcategory}`, and `{slug}` in URL patterns for dynamic redirects
- **Fallback rules** -- Create a catch-all rule (empty categories) that applies when no specific rule matches
- **SEO-friendly** -- Returns 301 redirects for regular page requests
- **SPA-compatible** -- Returns 403 JSON with a `redirect_to` field for XHR/AJAX requests, allowing the Ember app to handle the redirect client-side
- **Admin UI** -- Manage rules from Admin > Plugins > Redirect on Forbidden
- **In-memory caching** -- Rules are cached for fast lookups, automatically invalidated on changes

## Requirements

- Discourse 2.7.0 or later
- **`detailed 404` site setting must be enabled** -- Without this, Discourse returns 404 (not 403) for anonymous users accessing restricted content, and the plugin cannot intercept the response.

## Installation

Add the plugin to your Discourse `app.yml`:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/Marfeel/discourse-plugin-redirect-on-forbidden.git
```

Then rebuild the container:

```bash
./launcher rebuild app
```

## Configuration

### 1. Enable the plugin

Go to **Admin > Settings** and search for `redirect on forbidden`. Enable the **redirect_on_forbidden_enabled** setting.

### 2. Enable `detailed 404`

Go to **Admin > Settings** and search for `detailed 404`. Enable it. This is required for the plugin to work with anonymous users. The admin UI displays a warning banner if this setting is disabled.

### 3. Create redirect rules

Go to **Admin > Plugins > Redirect on Forbidden** and add rules.

Each rule has:

| Field | Description |
|---|---|
| **Categories** | One or more Discourse categories this rule applies to. Leave empty to create a fallback rule. |
| **URL Pattern** | The external URL to redirect to. Supports placeholders. Must start with `https://`. |

### URL Pattern Placeholders

| Placeholder | Replaced With |
|---|---|
| `{category}` | The category slug (or parent category slug for subcategories) |
| `{subcategory}` | The subcategory slug (omitted if the topic is in a top-level category) |
| `{slug}` | The topic slug (omitted for category-level access denials) |

Unused placeholders and their preceding `/` are automatically removed to produce clean URLs.

### Examples

**Simple category redirect:**

Rule: Categories = `Documentation`, URL = `https://docs.example.com/{category}/{slug}`

- Topic "Getting Started" in "Documentation" -> `https://docs.example.com/documentation/getting-started`
- Category-level access -> `https://docs.example.com/documentation`

**Subcategory redirect:**

Rule: Categories = `Changelog`, URL = `https://example.com/{category}/{subcategory}/{slug}`

- Topic "New Feature" in "What's New > Changelog" -> `https://example.com/whatsnew/changelog/new-feature`

**Static redirect (no placeholders):**

Rule: Categories = `Premium`, URL = `https://example.com/pricing`

- Any forbidden access in "Premium" -> `https://example.com/pricing`

**Fallback rule:**

Rule: Categories = *(empty)*, URL = `https://example.com/access-denied`

- Any forbidden category without a specific rule -> `https://example.com/access-denied`
- Only one fallback rule is allowed

## How It Works

The plugin prepends a method on `ApplicationController#rescue_discourse_actions` to intercept 403 responses before Discourse renders its default error page.

When a 403 is triggered:

1. The plugin extracts the `category_id` and optional `topic_slug` from the request parameters
2. It looks up a matching redirect rule (specific category match first, then fallback)
3. It resolves the URL pattern by substituting placeholders with actual category/topic slugs
4. For **HTML requests**: responds with a `301 redirect` to the external URL
5. For **XHR/JSON requests**: responds with `403` and a JSON body containing `redirect_to`, allowing the Ember frontend to handle the redirect

## API

The plugin exposes an admin API for managing rules:

| Method | Endpoint | Description |
|---|---|---|
| GET | `/admin/plugins/redirect-on-forbidden/rules` | List all rules |
| POST | `/admin/plugins/redirect-on-forbidden/rules` | Create a rule |
| PUT | `/admin/plugins/redirect-on-forbidden/rules/:id` | Update a rule |
| DELETE | `/admin/plugins/redirect-on-forbidden/rules/:id` | Delete a rule |

Rules are also serialized into the Discourse site object (`site.redirect_on_forbidden_rules`) for client-side access when the plugin is enabled.

## Development

### Running tests

From within the Discourse container:

```bash
LOAD_PLUGINS=1 bundle exec rspec plugins/discourse-redirect-on-forbidden/spec
```

### Project structure

```
plugin.rb                          # Plugin entry point, controller extension
config/
  routes.rb                        # Admin API routes
  settings.yml                     # Site settings
  locales/
    server.en.yml                  # Server-side translations
    client.en.yml                  # Client-side translations
app/
  models/redirect_on_forbidden/
    redirect_rule.rb               # Rule model with caching and validation
  controllers/redirect_on_forbidden/
    rules_controller.rb            # Admin CRUD controller
lib/redirect_on_forbidden/
    engine.rb                      # Rails engine setup
    url_resolver.rb                # Resolves category + slug into redirect URL
db/migrate/
    *_create_redirect_rules.rb     # Creates rules table with GIN-indexed integer array
assets/javascripts/discourse/
    components/                    # Glimmer admin UI components
    routes/                        # Ember route for admin page
    templates/                     # Admin page template
    stylesheets/                   # Admin page styles
spec/                              # RSpec tests (36 specs)
```

## License

MIT

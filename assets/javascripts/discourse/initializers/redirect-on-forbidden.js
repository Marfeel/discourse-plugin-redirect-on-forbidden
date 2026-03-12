import { withPluginApi } from "discourse/lib/plugin-api";
import $ from "jquery";

export default {
  name: "redirect-on-forbidden",

  initialize() {
    withPluginApi("1.0.0", (api) => {
      const siteSettings = api.container.lookup("service:site-settings");
      if (!siteSettings.redirect_on_forbidden_enabled) {
        return;
      }

      $(document).ajaxError((_event, jqXHR) => {
        if (
          jqXHR.status === 403 &&
          jqXHR.responseJSON?.redirect_to
        ) {
          window.location.replace(jqXHR.responseJSON.redirect_to);
        }
      });
    });
  },
};

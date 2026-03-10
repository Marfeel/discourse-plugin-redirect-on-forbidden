import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "redirect-on-forbidden",

  initialize() {
    withPluginApi("1.0.0", (api) => {
      const siteSettings = api.container.lookup("service:site-settings");
      if (!siteSettings.redirect_on_forbidden_enabled) {
        return;
      }

      api.modifyClass("controller:application", {
        pluginId: "redirect-on-forbidden",

        actions: {
          error(error) {
            if (
              error?.jqXHR?.status === 403 &&
              error?.jqXHR?.responseJSON?.redirect_to
            ) {
              window.location.replace(
                error.jqXHR.responseJSON.redirect_to,
              );
              return;
            }
            return this._super(...arguments);
          },
        },
      });
    });
  },
};

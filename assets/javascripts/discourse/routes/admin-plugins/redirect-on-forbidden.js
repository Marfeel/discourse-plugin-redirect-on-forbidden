import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";

export default class AdminPluginsRedirectOnForbiddenRoute extends DiscourseRoute {
  async model() {
    const data = await ajax("/admin/plugins/redirect-on-forbidden/rules");
    return {
      rules: data.rules || [],
      detailed404: data.detailed_404,
    };
  }
}

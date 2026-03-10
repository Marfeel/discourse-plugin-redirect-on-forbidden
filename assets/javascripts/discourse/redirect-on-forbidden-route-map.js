export default {
  resource: "admin.adminPlugins",
  path: "/plugins",
  map() {
    this.route("redirect-on-forbidden");
  },
};

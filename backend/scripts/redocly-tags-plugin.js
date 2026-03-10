// scripts/redocly-tags-plugin.js
module.exports = {
  id: "custom",
  decorators: {
    oas3: {
      "translate-tags": (options) => {
        const mapping = options.mapping || {};
        return {
          Tag: {
            enter(tag) {
              if (mapping[tag.name]) {
                tag.name = mapping[tag.name];
              }
            },
          },
          Operation: {
            enter(operation) {
              if (operation.tags) {
                operation.tags = operation.tags.map((t) => mapping[t] || t);
              }
            },
          },
        };
      },
    },
  },
};

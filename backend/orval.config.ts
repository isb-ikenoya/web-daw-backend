import { defineConfig } from "orval";

export default defineConfig({
  bff: {
    input: {
      target: "src/openapi/bff/spec/openapi.yaml",
    },
    output: {
      mode: "tags",
      target: "src/api/bff/endpoints",
      schemas: "src/api/bff/models",
      clean: true,
      prettier: true,
      client: "axios",
    },
  },
  /*voicevox: {
    input: {
      target: "src/openapi/voicevox/spec/openapi.yaml",
    },
    output: {
      mode: "tags",
      target: "src/api/voicevox/endpoints",
      schemas: "src/api/voicevox/models",
      clean: true,
      client: "axios",
    },
  },*/
  voicevox_synthesis: {
    input: {
      target: "src/openapi/voicevox/openapi.formatted.yaml",
      filters: {
        tags: ["speech_synthesis", "create_query"],
      },
    },
    output: {
      namingConvention: "camelCase",
      mode: "tags",
      target: "src/api/voicevox/synthesis/endpoints",
      schemas: "src/api/voicevox/models",
      clean: true,
      prettier: true,
      client: "axios-functions", // axiosだとファクトリ関数が作られてしまう
      override: {
        mutator: {
          path: "src/lib/custom-instance.ts",
          name: "customInstance",
        },
      },
    },
  },
});

import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["collectors/**/*.test.ts", "adapters/**/*.test.ts"],
    environment: "node",
  },
});

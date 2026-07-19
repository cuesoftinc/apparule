import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  // Override default ignores of eslint-config-next.
  globalIgnores([
    // Default ignores of eslint-config-next:
    ".next/**",
    "out/**",
    "build/**",
    "next-env.d.ts",
  ]),
  {
    // Legacy quarantine (web-implementation.md §1/§8): live paths carry zero
    // dead code — src/legacy is import-forbidden outside itself. Mirrored by
    // the CI-runnable `npm run check:boundaries` grep gate.
    files: ["src/**/*.{ts,tsx}"],
    ignores: ["src/legacy/**"],
    rules: {
      "no-restricted-imports": [
        "error",
        {
          patterns: [
            {
              group: ["**/legacy/**", "**/legacy", "@/legacy/**", "@/legacy"],
              message:
                "src/legacy is quarantined — live paths must not import legacy code (web-implementation.md legacy policy).",
            },
          ],
        },
      ],
    },
  },
]);

export default eslintConfig;

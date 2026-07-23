import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";
import testingLibrary from "eslint-plugin-testing-library";

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
    // Import boundaries (org web standard §8 + MVC): the legacy quarantine
    // (web-implementation.md §1/§8: live paths carry zero dead code —
    // src/legacy is import-forbidden outside itself) plus the org-wide
    // package bans. Mirrored by the CI-runnable `npm run check:boundaries`
    // grep gate.
    files: ["src/**/*.{ts,tsx}"],
    ignores: ["src/legacy/**"],
    rules: {
      "no-restricted-imports": [
        "error",
        {
          patterns: [
            {
              group: ["@mui/*", "@emotion/*"],
              message:
                "Styled component kits are banned (web-implementation.md component-reuse policy); build from the token layer.",
            },
            {
              group: ["dayjs", "moment"],
              message:
                "date-fns is the canonical date library (org SKILL) — use @/lib/format helpers.",
            },
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
  // Testing Library lint (org web standard): the flat/react preset, scoped
  // to the co-located unit/component tests.
  {
    files: ["src/**/*.test.{ts,tsx}"],
    ...testingLibrary.configs["flat/react"],
    rules: {
      ...testingLibrary.configs["flat/react"].rules,
      // The component-reuse policy (web-implementation.md) builds all visual
      // components bespoke from the token layer — their tests assert
      // non-semantic structure (SVG geometry, token classes) that has no
      // role/label to query, so container/node access is the intended
      // pattern, not a smell.
      "testing-library/no-container": "off",
      "testing-library/no-node-access": "off",
    },
  },
]);

export default eslintConfig;

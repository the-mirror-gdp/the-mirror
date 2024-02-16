module.exports = {
  parser: '@typescript-eslint/parser',
  parserOptions: {
    project: 'tsconfig.json',
    sourceType: 'module'
  },
  plugins: ['@typescript-eslint/eslint-plugin'],
  extends: [
    'plugin:@typescript-eslint/recommended',
    'plugin:prettier/recommended'
  ],
  root: true,
  env: {
    node: true,
    jest: true
  },
  ignorePatterns: ['.eslintrc.js'],
  rules: {
    '@typescript-eslint/interface-name-prefix': 'off',
    '@typescript-eslint/explicit-function-return-type': 'off',
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    '@typescript-eslint/no-explicit-any': 'off',
    '@typescript-eslint/ban-ts-ignore': 'off',
    '@typescript-eslint/ban-ts-comment': 'warn',
    '@typescript-eslint/no-var-requires': 'warn',
    semi: 'off',
    'prettier/prettier': [
      'error',
      {
        endOfLine: 'auto'
      }
    ],
    // Added 2023-08-27 22:13:33
    '@typescript-eslint/await-thenable': 'error',
    '@typescript-eslint/require-await': 'error',
    '@typescript-eslint/restrict-template-expressions': 'error',
    'require-await': 'error',

    // TODO add these in. This is the partial from my PR that I time-boxed and ran into issues, so I didn't merge: https://github.com/the-mirror-megaverse/mirror-server/pull/485/files
    // This is a paste of recommended-type-checked.ts as of Aug 25th '23: https://github.com/typescript-eslint/typescript-eslint/blob/main/packages/eslint-plugin/src/configs/recommended-type-checked.ts
    // This is MODIFIED; I didn't use the above recommended so I could modify individual rules.
    // '@typescript-eslint/await-thenable': 'error',
    // '@typescript-eslint/ban-ts-comment': 'warn',
    // '@typescript-eslint/ban-types': 'error',
    // 'no-array-constructor': 'off',
    // '@typescript-eslint/no-array-constructor': 'error',
    // '@typescript-eslint/no-base-to-string': 'error',
    // '@typescript-eslint/no-duplicate-enum-values': 'error',
    // '@typescript-eslint/no-duplicate-type-constituents': 'error',
    // '@typescript-eslint/no-explicit-any': 'off',
    // '@typescript-eslint/no-extra-non-null-assertion': 'error',
    // // TODO: this should be 'error', but I don't want to refactor everything in this PR.
    // '@typescript-eslint/no-floating-promises': 'warn',
    // '@typescript-eslint/no-for-in-array': 'error',
    // 'no-implied-eval': 'off',
    // '@typescript-eslint/no-implied-eval': 'error',
    // 'no-loss-of-precision': 'off',
    // '@typescript-eslint/no-loss-of-precision': 'error',
    // '@typescript-eslint/no-misused-new': 'error',
    // '@typescript-eslint/no-misused-promises': 'error',
    // '@typescript-eslint/no-namespace': 'error',
    // '@typescript-eslint/no-non-null-asserted-optional-chain': 'error',
    // '@typescript-eslint/no-redundant-type-constituents': 'error',
    // '@typescript-eslint/no-this-alias': 'error',
    // '@typescript-eslint/no-unnecessary-type-assertion': 'error',
    // '@typescript-eslint/no-unnecessary-type-constraint': 'error',
    // '@typescript-eslint/no-unsafe-argument': 'warn',
    // '@typescript-eslint/no-unsafe-assignment': 'warn',
    // '@typescript-eslint/no-unsafe-call': 'warn',
    // '@typescript-eslint/no-unsafe-declaration-merging': 'error',
    // '@typescript-eslint/no-unsafe-enum-comparison': 'warn',
    // '@typescript-eslint/no-unsafe-member-access': 'warn',
    // '@typescript-eslint/no-unsafe-return': 'warn',
    // 'no-unused-vars': 'off',
    // '@typescript-eslint/no-unused-vars': 'warn',
    // '@typescript-eslint/no-var-requires': 'warn',
    // '@typescript-eslint/prefer-as-const': 'error',
    // '@typescript-eslint/require-await': 'error',
    // '@typescript-eslint/restrict-plus-operands': 'error',
    // '@typescript-eslint/restrict-template-expressions': 'error',
    // '@typescript-eslint/triple-slash-reference': 'error',
    // '@typescript-eslint/unbound-method': 'error',

    // // This is a paste of stylistic-type-checked.ts as of Aug 25th '23: https://github.com/typescript-eslint/typescript-eslint/blob/main/packages/eslint-plugin/src/configs/stylistic-type-checked.ts
    // // This is MODIFIED; I didn't use the above recommended so I could modify individual rules.
    // '@typescript-eslint/adjacent-overload-signatures': 'error',
    // '@typescript-eslint/array-type': 'error',
    // '@typescript-eslint/ban-tslint-comment': 'error',
    // '@typescript-eslint/class-literal-property-style': 'error',
    // '@typescript-eslint/consistent-generic-constructors': 'error',
    // '@typescript-eslint/consistent-indexed-object-style': 'error',
    // '@typescript-eslint/consistent-type-assertions': 'error',
    // '@typescript-eslint/consistent-type-definitions': 'error',
    // 'dot-notation': 'off',
    // '@typescript-eslint/dot-notation': 'warn',
    // '@typescript-eslint/no-confusing-non-null-assertion': 'error',
    // 'no-empty-function': 'off',
    // '@typescript-eslint/no-empty-function': 'error',
    // '@typescript-eslint/no-empty-interface': 'error',
    // '@typescript-eslint/no-inferrable-types': 'error',
    // '@typescript-eslint/non-nullable-type-assertion-style': 'error',
    // '@typescript-eslint/prefer-for-of': 'error',
    // '@typescript-eslint/prefer-function-type': 'error',
    // '@typescript-eslint/prefer-namespace-keyword': 'error',
    // // commented out because we have strictNullChecks set to false
    // // '@typescript-eslint/prefer-nullish-coalescing': 'warn',
    // '@typescript-eslint/prefer-optional-chain': 'error',
    // '@typescript-eslint/prefer-string-starts-ends-with': 'error',
  },
  overrides: [
    {
      files: ['test/**/*'],
      rules: {
        // These are here since we don't need to be as strict for tests, such as the usgae of `any`, which often comes in handy when writing tests quickly since defining types for tests can take a lot of time.
        '@typescript-eslint/no-var-requires': 'warn',
        '@typescript-eslint/require-await': 'warn',
        'require-await': 'warn',
        '@typescript-eslint/restrict-template-expressions': 'warn',
        '@typescript-eslint/no-empty-function': 'warn',

        '@typescript-eslint/no-unsafe-argument': 'off',
        '@typescript-eslint/no-unsafe-assignment': 'off',
        '@typescript-eslint/no-unsafe-call': 'off',
        '@typescript-eslint/no-unsafe-declaration-merging': 'error',
        '@typescript-eslint/no-unsafe-enum-comparison': 'warn',
        '@typescript-eslint/no-unsafe-member-access': 'off',
        '@typescript-eslint/no-unsafe-return': 'warn',
        '@typescript-eslint/no-inferrable-types': 'warn',
        '@typescript-eslint/ban-types': 'warn',

      }

    }
  ]
}

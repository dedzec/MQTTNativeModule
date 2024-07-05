module.exports = {
  root: true,
  parser: '@babel/eslint-parser',
  parserOptions: {
    ecmaVersion: 2021,
    sourceType: 'module',
    ecmaFeatures: {
      jsx: true,
    },
  },
  plugins: ['react', 'react-native', 'prettier'],
  env: {
    'react-native/react-native': true,
    es6: true,
    node: true,
  },
  extends: [
    'eslint:recommended',
    'plugin:react/recommended',
    'plugin:react-native/all',
    'plugin:prettier/recommended',
  ],
  rules: {
    'react/prop-types': 0,
    'react/display-name': 0,
    'react/react-in-jsx-scope': 'off', // React 17+ doesn't require React to be in scope
    'react-native/no-inline-styles': 0,
    'react-native/sort-styles': 'off',
    'react-native/no-color-literals': 'off',
    'react-native/no-unused-styles': 'off',
    'no-extra-boolean-cast': 'off',
    'react-native/no-single-element-style-arrays': 'off',
    'prettier/prettier': [
      'error',
      {
        endOfLine: 'auto',
      },
    ],
  },
  settings: {
    react: {
      version: 'detect',
    },
  },
};

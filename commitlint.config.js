module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',
        'fix',
        'docs',
        'test',
        'refactor',
        'chore',
        'ci',
        'perf',
        'build',
        'revert',
        'style',
      ],
    ],
    'subject-case': [0],
  },
};

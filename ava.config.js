export default {
  compileEnhancements: false,
  files: ['src/*.test.ts'],
  extensions: ['ts'],
  require: ['ts-node/register'],
  tap: true,
  verbose: true,
};

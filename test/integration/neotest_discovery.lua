local I = dofile(vim.fn.stdpath 'config' .. '/test/integration/_lib.lua')
local H = dofile(vim.fn.stdpath 'config' .. '/test/spec/helpers.lua')

I.check('neotest adapters load and claim their test files', function()
  for _, mod in ipairs {
    'neotest-gtest',
    'neotest-jest',
    'neotest-vitest',
    'neotest-phpunit',
    'neotest-java',
    'neotest-golang',
    'neotest-python',
  } do
    assert(pcall(require, mod), 'cannot require ' .. mod)
  end

  local gtest = require('neotest-gtest').setup {}
  assert(gtest.is_test_file(H.fixture 'cpp/sample_test.cpp'), 'gtest does not claim sample_test.cpp')

  local spock = require 'util.neotest_gradle_spock'()
  assert(spock.is_test_file(H.fixture 'groovy/src/test/groovy/AdderSpec.groovy'), 'spock does not claim AdderSpec.groovy')
  assert(not spock.is_test_file(H.fixture 'java/src/main/java/App.java'), 'spock claims a non-test file')
end)
I.finish()

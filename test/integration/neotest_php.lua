local I = dofile(vim.fn.stdpath 'config' .. '/test/integration/_lib.lua')
local H = dofile(vim.fn.stdpath 'config' .. '/test/spec/helpers.lua')

I.check('neotest php', function()
  local p, f = I.run('neotest-phpunit', H.fixture 'php', H.fixture 'php/tests/AdderTest.php', 180000)
  assert(p >= 1, 'expected >=1 passing php test')
  assert(f == 0, 'unexpected failing php tests')
end)
I.finish()

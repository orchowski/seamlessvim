local I = dofile(vim.fn.stdpath 'config' .. '/test/integration/_lib.lua')
local H = dofile(vim.fn.stdpath 'config' .. '/test/spec/helpers.lua')

I.check('neotest python', function()
  local p, f = I.run('neotest-python', H.fixture 'python', H.fixture 'python/hello_test.py', 120000)
  assert(p >= 1, 'expected >=1 passing python test')
  assert(f == 0, 'unexpected failing python tests')
end)
I.finish()

local I = dofile(vim.fn.stdpath 'config' .. '/test/integration/_lib.lua')
local H = dofile(vim.fn.stdpath 'config' .. '/test/spec/helpers.lua')

I.check('neotest go', function()
  local p, f = I.run('neotest-golang', H.fixture 'go', H.fixture 'go/hello_test.go', 120000)
  assert(p >= 1, 'expected >=1 passing go test')
  assert(f == 0, 'unexpected failing go tests')
end)
I.finish()

-- Helpers for plain integration scripts (run outside plenary-busted).
-- Files starting with "_" are ignored by test/docker/inside.sh.

local H = dofile(vim.fn.stdpath 'config' .. '/test/spec/helpers.lua')
local neotest = require 'neotest'

local M = { passed = 0, failed = 0 }

function M.check(name, fn)
  local ok, err = pcall(fn)
  if ok then
    M.passed = M.passed + 1
    print('Success || ' .. name)
  else
    M.failed = M.failed + 1
    print('Fail    || ' .. name .. ' -> ' .. tostring(err))
  end
end

function M.adapter_counts(prefix)
  for _, id in ipairs(neotest.state.adapter_ids()) do
    if id:sub(1, #prefix) == prefix then
      return neotest.state.status_counts(id)
    end
  end
end

--- cd into `dir`, open `file`, run it and wait for `prefix` adapter to finish.
--- Returns passed, failed counts for that adapter.
function M.run(prefix, dir, file, timeout)
  vim.cmd.cd(dir)
  vim.cmd.edit(file)
  neotest.run.run(file)
  H.wait(function()
    local c = M.adapter_counts(prefix)
    return c ~= nil and c.running == 0 and (c.passed + c.failed + c.skipped) > 0
  end, timeout, prefix .. ' run')
  local c = M.adapter_counts(prefix)
  return c.passed, c.failed
end

function M.finish()
  print(string.format('\nSuccess: %d\nFailed : %d', M.passed, M.failed))
  if M.failed > 0 then
    vim.cmd 'cq'
  else
    vim.cmd 'qa!'
  end
end

return M

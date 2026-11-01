-- Verifies the debugger: adapters, launch configurations and a real
-- breakpoint smoke test for delve (Go) and debugpy (Python).

local H = dofile(vim.fn.stdpath 'config' .. '/test/spec/helpers.lua')
local dap = require 'dap'

describe('dap adapters', function()
  it('load plugins', function()
    require('lazy').load { plugins = vim.tbl_keys(require('lazy.core.config').plugins) }
  end)

  for _, name in ipairs { 'go', 'php', 'python', 'pwa-node', 'codelldb' } do
    it('adapter ' .. name, function()
      assert(dap.adapters[name] ~= nil, 'missing dap adapter: ' .. name)
    end)
  end
end)

describe('dap configurations', function()
  for _, ft in ipairs { 'go', 'php', 'python', 'javascript', 'typescript', 'c', 'cpp', 'java' } do
    it('configurations for ' .. ft, function()
      local cfgs = dap.configurations[ft]
      assert(cfgs and #cfgs > 0, 'no dap configurations for ' .. ft)
    end)
  end
end)

describe('dap breakpoint smoke', function()
  local function stop_flag()
    local flag = { stopped = false }
    dap.listeners.after.event_stopped['spec'] = function()
      flag.stopped = true
    end
    return flag
  end

  it('delve stops on a Go breakpoint', function()
    vim.cmd.edit(H.fixture 'go/hello.go')
    vim.api.nvim_win_set_cursor(0, { 6, 0 }) -- return a + b
    dap.toggle_breakpoint()
    local flag = stop_flag()
    dap.run {
      type = 'go',
      request = 'launch',
      name = 'spec-go',
      mode = 'debug',
      program = H.fixture 'go/hello.go',
    }
    H.wait(function()
      return flag.stopped
    end, 90000, 'delve stop')
    dap.terminate()
    dap.listeners.after.event_stopped['spec'] = nil
  end)

  it('debugpy stops on a Python breakpoint', function()
    vim.cmd.edit(H.fixture 'python/hello.py')
    vim.api.nvim_win_set_cursor(0, { 2, 0 }) -- return a + b
    dap.toggle_breakpoint()
    local flag = stop_flag()
    dap.run {
      type = 'python',
      request = 'launch',
      name = 'spec-python',
      program = H.fixture 'python/hello.py',
    }
    H.wait(function()
      return flag.stopped
    end, 90000, 'debugpy stop')
    dap.terminate()
    dap.listeners.after.event_stopped['spec'] = nil
  end)
end)

-- Verifies the keyboard-shortcut contract is preserved.

local H = dofile(vim.fn.stdpath 'config' .. '/test/spec/helpers.lua')

local global = {
  n = {
    '<Esc>',
    '<leader>q',
    '<C-h>',
    '<C-l>',
    '<C-j>',
    '<C-k>',
    '<leader>yp',
    '<leader>cp',
    '<leader>dh',
    '<leader>ds',
    -- telescope
    '<leader>sh',
    '<leader>sk',
    '<leader>sf',
    '<leader>ss',
    '<leader>sw',
    '<leader>sg',
    '<leader>sd',
    '<leader>sr',
    '<leader>s.',
    '<leader><leader>',
    '<leader>/',
    '<leader>s/',
    '<leader>sn',
    -- format
    '<leader>f',
    -- harpoon
    '<leader>ha',
    '<leader>hh',
    '<leader>h1',
    '<leader>h2',
    '<leader>h3',
    '<leader>h4',
    '<leader>hn',
    '<leader>hp',
    -- neo-tree
    '<C-n>',
    '<A-s>',
    -- dap
    '<F5>',
    '<F1>',
    '<F2>',
    '<F3>',
    '<leader>b',
    '<leader>B',
    '<F7>',
    -- neotest
    '<leader>tn',
    '<leader>tf',
    '<leader>td',
    '<leader>ts',
    '<leader>to',
    '<leader>tp',
    '<leader>tw',
    '<leader>tW',
    '<leader>ta',
    -- gopher
    '<leader>ggi',
    '<leader>ggt',
    '<leader>gga',
    '<leader>ggr',
    '<leader>ggf',
  },
  t = { '<Esc><Esc>' },
}

describe('global keymaps', function()
  it('load all lazy plugins', function()
    require('lazy').load { plugins = vim.tbl_keys(require('lazy.core.config').plugins) }
  end)

  for mode, lhs_list in pairs(global) do
    for _, lhs in ipairs(lhs_list) do
      it(mode .. ' ' .. lhs, function()
        assert(H.has_map(mode, lhs), 'missing keymap: ' .. mode .. ' ' .. lhs)
      end)
    end
  end
end)

describe('gitsigns buffer keymaps', function()
  local buf
  it('gitsigns attaches to a tracked buffer', function()
    local file = H.git_fixture()
    vim.cmd.edit(file)
    buf = vim.api.nvim_get_current_buf()
    H.wait(function()
      return H.has_map('n', '<leader>hS', buf)
    end, 20000, 'gitsigns attach')
  end)

  for _, case in ipairs {
    { 'n', ']c' },
    { 'n', '[c' },
    { 'n', '<leader>hs' },
    { 'n', '<leader>hr' },
    { 'n', '<leader>hS' },
    { 'n', '<leader>hu' },
    { 'n', '<leader>hR' },
    { 'n', '<leader>hP' },
    { 'n', '<leader>hb' },
    { 'n', '<leader>hd' },
    { 'n', '<leader>hD' },
    { 'n', '<leader>tb' },
    { 'n', '<leader>tD' },
    { 'v', '<leader>hs' },
    { 'v', '<leader>hr' },
  } do
    it('gitsigns ' .. case[1] .. ' ' .. case[2], function()
      assert(H.has_map(case[1], case[2], buf), 'missing: ' .. case[1] .. ' ' .. case[2])
    end)
  end
end)

describe('csvview buffer keymaps', function()
  local buf
  it('enables csv view', function()
    local file = vim.fn.tempname() .. '.csv'
    vim.fn.writefile({ 'a,b,c', '1,2,3' }, file)
    vim.cmd.edit(file)
    vim.cmd 'CsvViewEnable'
    buf = vim.api.nvim_get_current_buf()
  end)

  for _, case in ipairs {
    { 'n', '<Tab>' },
    { 'n', '<S-Tab>' },
    { 'n', '<Enter>' },
    { 'n', '<S-Enter>' },
    { 'x', 'if' },
    { 'x', 'af' },
  } do
    it('csvview ' .. case[1] .. ' ' .. case[2], function()
      assert(H.has_map(case[1], case[2], buf), 'missing: ' .. case[1] .. ' ' .. case[2])
    end)
  end
end)

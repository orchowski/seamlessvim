return {
  'olexsmir/gopher.nvim',
  ft = 'go',
  -- branch = "develop"
  -- (optional) will update plugin's deps on every update
  build = function()
    vim.cmd.GoInstallDeps()
  end,
  ---@type gopher.Config
  opts = {},
  keys = {
    { '<leader>ggi', '<cmd>GoIfErr<cr>', desc = 'Gopher: if err' },
    { '<leader>ggt', '<cmd>GoTagAdd json<cr>', desc = 'Gopher: struct tag json' },
    { '<leader>gga', '<cmd>GoAlt!<cr>', desc = 'Gopher: switch impl/test' },
    { '<leader>ggr', '<cmd>GoTestFunc<cr>', desc = 'Gopher: run current test' },
    { '<leader>ggf', '<cmd>GoTestFile<cr>', desc = 'Gopher: run test file' },
  },
}

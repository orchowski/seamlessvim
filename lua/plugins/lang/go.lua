-- Go tooling: gopher.nvim (if-err, struct tags, alt file) + :SetGoBuildTags.
-- Go DAP launch configurations live in dap.lua (single nvim-dap config).

return {
  'olexsmir/gopher.nvim',
  ft = 'go',
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
  config = function(_, opts)
    require('gopher').setup(opts)

    -- Switch Go build tags for gopls/completions without touching project files.
    vim.api.nvim_create_user_command('SetGoBuildTags', function(cmd_opts)
      if #cmd_opts.fargs == 0 then
        print 'Usage: :SetGoBuildTags <tag1> <tag2> ...'
        return
      end

      local tags = table.concat(cmd_opts.fargs, ',')
      local val = '-tags=' .. tags

      vim.fn.setenv('GOFLAGS', val)
      print('GOFLAGS set to: ' .. val)

      vim.cmd 'LspRestart'
    end, {
      nargs = '+',
      complete = function()
        return { 'unit', 'integration', 'e2e' }
      end,
    })
  end,
}

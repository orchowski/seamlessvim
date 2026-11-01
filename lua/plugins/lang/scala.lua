-- Scala: nvim-metals owns the Metals client (it bootstraps the `metals` binary
-- via coursier with :MetalsInstall and wires debug/test support itself).

return {
  'scalameta/nvim-metals',
  ft = 'scala',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'mfussenegger/nvim-dap',
  },
  config = function()
    local metals = require 'metals'
    local metals_config = metals.bare_config()

    -- Use the `metals` launcher installed by coursier (`cs install metals`,
    -- see install.sh) instead of letting nvim-metals bootstrap its own copy.
    local coursier_bin = vim.fn.expand '~/.local/share/coursier/bin'
    if vim.uv.fs_stat(coursier_bin .. '/metals') and not vim.env.PATH:find(coursier_bin, 1, true) then
      vim.env.PATH = coursier_bin .. ':' .. vim.env.PATH
    end

    metals_config.settings = {
      useGlobalExecutable = true,
      showImplicitArguments = true,
      showInferredType = true,
      superMethodLensesEnabled = true,
    }

    metals_config.init_options.statusBarProvider = 'off'
    metals_config.capabilities = require('blink.cmp').get_lsp_capabilities()

    metals_config.on_attach = function(_, bufnr)
      local map = function(keys, func, desc)
        vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'Scala: ' .. desc })
      end
      map('<leader>co', metals.organize_imports, 'Organize imports')
      map('<leader>ci', metals.import_build, 'Import build')
      map('<leader>cr', metals.restart_metals, 'Restart server')
    end

    -- Wire Metals into nvim-dap (debug + test).
    metals.setup_dap()

    local group = vim.api.nvim_create_augroup('seamlessvim-metals', { clear = true })
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'scala',
      callback = function()
        metals.initialize_or_attach(metals_config)
      end,
      group = group,
    })
    -- ft-loading runs after the FileType event, so start for the current buffer too.
    if vim.bo.filetype == 'scala' then
      metals.initialize_or_attach(metals_config)
    end
  end,
}

-- Core autocommands (no plugin dependencies).
-- LSP-related autocmds live in lua/plugins/lsp.lua, lint triggers in lua/plugins/lint.lua.

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('seamlessvim-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

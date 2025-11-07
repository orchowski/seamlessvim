-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
vim.keymap.set('n', '<leader>yp', function()
  local rel = vim.fn.expand '%:.'
  vim.fn.setreg('"', rel) -- default register
  pcall(vim.fn.setreg, '+', rel) -- system clipboard (if available)
end, { desc = 'Copy path relative to CWD' })
return {
  --  EXAMPLE
  --  {
  --    "nvim-neo-tree/neo-tree.nvim",
  --    keys = {
  --      { "<C-n>", ":Neotree reveal<CR>", desc = "NeoTree reveal", silent = true },
  --    },
  --  },
}

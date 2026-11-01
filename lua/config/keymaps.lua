-- Core keymaps (no plugin dependencies).
-- Plugin keymaps live next to their plugin spec (telescope.lua, harpoon.lua, ...).

-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode with <Esc><Esc>
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Window navigation
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Copy current file path (relative to CWD) into default + system registers
vim.keymap.set('n', '<leader>yp', function()
  local rel = vim.fn.expand '%:.'
  vim.fn.setreg('"', rel)
  pcall(vim.fn.setreg, '+', rel)
end, { desc = 'Copy path relative to CWD' })

-- Copy current file path (relative to CWD) into the system clipboard only
vim.keymap.set('n', '<leader>cp', function()
  local path = vim.fn.expand '%:.'
  vim.fn.setreg('+', path)
  print('Skopiowano: ' .. path)
end, { desc = 'Copy relative file path to clipboard' })

-- Diagnostic virtual text on/off
vim.keymap.set('n', '<leader>dh', function()
  vim.diagnostic.config { virtual_text = false }
end, { desc = 'Hide diagnostic virtual text' })

vim.keymap.set('n', '<leader>ds', function()
  vim.diagnostic.config { virtual_text = true }
end, { desc = 'Show diagnostic virtual text' })

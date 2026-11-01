-- seamlessvim — modular Neovim config (no kickstart).
-- Layout:
--   lua/config/  -> editor core (options, keymaps, autocmds, plugin manager)
--   lua/plugins/ -> plugin specs, one file per area
--   lua/plugins/lang/ -> heavyweight language tooling (jdtls, metals, gopher, ...)
-- See README.md for the full keymap table.

vim.g.mapleader = ' '
vim.g.maplocalleader = "'"
vim.g.have_nerd_font = true

require 'config.options'
require 'config.lazy'
require 'config.keymaps'
require 'config.autocmds'

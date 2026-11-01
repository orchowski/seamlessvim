-- Tree-sitter (nvim-treesitter rewrite, branch `main`).
-- The rewrite no longer auto-enables highlighting or indentation, so both are
-- switched on here for every buffer that has a parser.

return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false,
  build = ':TSUpdate',
  config = function()
    local parsers = require 'config.parsers'

    require('nvim-treesitter').install(parsers)

    local indent_disabled = { ruby = true }

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('seamlessvim-treesitter', { clear = true }),
      callback = function(args)
        local buf = args.buf
        if vim.treesitter.highlighter.active[buf] then
          return
        end
        if not pcall(vim.treesitter.start, buf) then
          return
        end
        if not indent_disabled[vim.bo[buf].filetype] then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}

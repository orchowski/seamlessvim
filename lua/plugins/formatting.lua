-- Formatting via conform.nvim.
--
-- On-save formatting is disabled for c/cpp/php (as before); PHP additionally has
-- its LSP formatting capability stripped in lsp.lua. Those three still format
-- manually via <leader>f (clang-format / php-cs-fixer).

return {
  'stevearc/conform.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>f',
      function()
        require('conform').format { async = true, lsp_format = 'fallback' }
      end,
      mode = '',
      desc = '[F]ormat buffer',
    },
  },
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      local disable_filetypes = { c = true, cpp = true, php = true }
      if disable_filetypes[vim.bo[bufnr].filetype] then
        return nil
      end
      return {
        timeout_ms = 500,
        lsp_format = 'fallback',
      }
    end,
    formatters_by_ft = {
      lua = { 'stylua' },
      python = { 'isort', 'black' },
      sh = { 'shfmt' },
      bash = { 'shfmt' },
      zsh = { 'shfmt' },
      markdown = { 'prettierd', 'prettier', stop_after_first = true },
      yaml = { 'prettierd', 'prettier', stop_after_first = true },
      json = { 'prettierd', 'prettier', stop_after_first = true },
      jsonc = { 'prettierd', 'prettier', stop_after_first = true },
      toml = { 'taplo' },
      javascript = { 'prettierd', 'prettier', stop_after_first = true },
      javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
      typescript = { 'prettierd', 'prettier', stop_after_first = true },
      typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
      go = { 'goimports', 'gofumpt' },
      java = { 'google-java-format' },
      kotlin = { 'ktlint' },
      scala = { 'scalafmt' },
      -- manual formatting only (format_on_save disabled above)
      c = { 'clang-format' },
      cpp = { 'clang-format' },
      php = { 'php-cs-fixer', 'pint', stop_after_first = true },
    },
  },
}

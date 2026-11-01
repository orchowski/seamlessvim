-- Kotlin: kotlin.nvim owns the JetBrains kotlin-lsp client (the server asks for
-- configuration on the fly; a bare lspconfig client leaves inlay hints empty and
-- completions land twice). The server bundles its own JBR, but mason still
-- installs the kotlin-lsp package (see lsp.lua).

return {
  'AlexandrosAlexiou/kotlin.nvim',
  ft = 'kotlin',
  dependencies = {
    'mason-org/mason.nvim',
  },
  config = function()
    local kotlin = require 'kotlin'
    kotlin.setup {}
    -- ft-loading runs after the FileType event, so start the server for the
    -- buffer that triggered the load.
    if vim.bo.filetype == 'kotlin' then
      kotlin.setup_kotlin_lsp {}
    end
  end,
}

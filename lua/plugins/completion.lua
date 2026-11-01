-- Autocompletion: blink.cmp + LuaSnip snippets.

return {
  {
    'L3MON4D3/LuaSnip',
    version = '2.*',
    build = (function()
      if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
        return
      end
      return 'make install_jsregexp'
    end)(),
    opts = {},
  },

  {
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      'L3MON4D3/LuaSnip',
      'folke/lazydev.nvim',
    },
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- 'default' preset: <c-y> accept, <tab>/<s-tab> snippet jump,
      -- <c-space> menu/docs, <c-n>/<c-p> select, <c-e> hide, <c-k> signature
      keymap = { preset = 'default' },

      appearance = {
        nerd_font_variant = 'normal',
      },

      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 500 },
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'lazydev' },
        providers = {
          lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
        },
      },

      snippets = { preset = 'luasnip' },

      fuzzy = { implementation = 'lua' },

      signature = { enabled = true },
    },
  },
}

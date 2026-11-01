-- UI: colorscheme, which-key, statusline, indent guides, todo highlights.

return {
  -- Everforest is the active colorscheme. The rest are kept as switchable
  -- alternatives (:Telescope colorscheme or :colorscheme <name>).
  {
    'neanias/everforest-nvim',
    version = false,
    lazy = false,
    priority = 1000,
    config = function()
      require('everforest').setup {
        everforest_background = 'soft',
      }
      vim.cmd.colorscheme 'everforest'
    end,
  },
  { 'catppuccin/nvim', name = 'catppuccin', lazy = true, priority = 1000 },
  { 'shaunsingh/nord.nvim', name = 'nord', lazy = true, priority = 1000 },
  { 'caglartoklu/borlandp.vim', name = 'borlandp', lazy = true, priority = 1000 },
  {
    'folke/tokyonight.nvim',
    lazy = true,
    priority = 1000,
    opts = { styles = { comments = { italic = false } } },
  },

  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      delay = 0,
      icons = {
        mappings = vim.g.have_nerd_font,
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },
      spec = {
        { '<leader>s', group = '[S]earch' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk / Harpoon', mode = { 'n', 'v' } },
        { '<leader>g', group = '[G]o tooling' },
      },
    },
  },

  {
    'echasnovski/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }

      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },

  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    opts = {},
  },

  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
}

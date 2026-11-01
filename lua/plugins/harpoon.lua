-- Harpoon 2: mark files and jump between them with <leader>h{a,h,1-4,n,p}.
-- (Migrated from Harpoon v1 API; marks persist in ~/.local/share/nvim/harpoon.json.)

return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = {
    { '<leader>ha', desc = 'Harpoon: [a]dd file' },
    { '<leader>hh', desc = 'Harpoon: quick menu' },
    { '<leader>h1', desc = 'Harpoon: goto [1]' },
    { '<leader>h2', desc = 'Harpoon: goto [2]' },
    { '<leader>h3', desc = 'Harpoon: goto [3]' },
    { '<leader>h4', desc = 'Harpoon: goto [4]' },
    { '<leader>hn', desc = 'Harpoon: [n]ext mark' },
    { '<leader>hp', desc = 'Harpoon: [p]revious mark' },
  },
  config = function()
    local harpoon = require 'harpoon'
    harpoon:setup {
      settings = {
        -- v1 compat: `save_on_change = true` -> always persist to harpoon.json
        save_on_toggle = true,
        sync_on_ui_close = true,
      },
    }

    vim.keymap.set('n', '<leader>ha', function()
      harpoon:list():add()
    end, { desc = 'Harpoon: [a]dd file' })
    vim.keymap.set('n', '<leader>hh', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = 'Harpoon: quick menu' })
    vim.keymap.set('n', '<leader>h1', function()
      harpoon:list():select(1)
    end, { desc = 'Harpoon: goto [1]' })
    vim.keymap.set('n', '<leader>h2', function()
      harpoon:list():select(2)
    end, { desc = 'Harpoon: goto [2]' })
    vim.keymap.set('n', '<leader>h3', function()
      harpoon:list():select(3)
    end, { desc = 'Harpoon: goto [3]' })
    vim.keymap.set('n', '<leader>h4', function()
      harpoon:list():select(4)
    end, { desc = 'Harpoon: goto [4]' })
    vim.keymap.set('n', '<leader>hn', function()
      harpoon:list():next()
    end, { desc = 'Harpoon: [n]ext mark' })
    vim.keymap.set('n', '<leader>hp', function()
      harpoon:list():prev()
    end, { desc = 'Harpoon: [p]revious mark' })
  end,
}

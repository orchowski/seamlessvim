return {
  -- Dodajemy wymagany plugin Plenary
  { 'nvim-lua/plenary.nvim' },

  -- Dodajemy plugin Harpoon
  {
    'ThePrimeagen/harpoon',
    config = function()
      -- Inicjalizacja Harpoon z globalnymi ustawieniami
      require('harpoon').setup {
        -- Globalne ustawienia
        global_settings = {
          -- Ustawia markery przy wywołaniu `toggle` na UI, zamiast wymagać `:w`
          save_on_toggle = false,

          -- Zapisuje plik harpoon przy każdej zmianie
          save_on_change = true,

          -- Uruchamia polecenie natychmiast po wysłaniu do terminala przy `sendCommand`
          enter_on_sendcmd = false,

          -- Zamyka okna tmux, które Harpoon tworzy, gdy zamykasz Neovim
          tmux_autoclose_windows = false,

          -- Typy plików, które chcesz wykluczyć z menu Harpoon
          excluded_filetypes = { 'harpoon' },

          -- Ustawia markery specyficzne dla każdej gałęzi git w repozytorium
          mark_branch = false,

          -- Włącza tablinę z markerami Harpoon
          tabline = false,
          tabline_prefix = '   ',
          tabline_suffix = '   ',
        },
      }

      -- Konfiguracja skrótów klawiszowych
      vim.api.nvim_set_keymap('n', '<leader>ha', ":lua require('harpoon.mark').add_file()<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>hh', ":lua require('harpoon.ui').toggle_quick_menu()<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>h1', ":lua require('harpoon.ui').nav_file(1)<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>h2', ":lua require('harpoon.ui').nav_file(2)<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>h3', ":lua require('harpoon.ui').nav_file(3)<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>h4', ":lua require('harpoon.ui').nav_file(4)<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>hn', ":lua require('harpoon.ui').nav_next()<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>hp', ":lua require('harpoon.ui').nav_prev()<CR>", { noremap = true, silent = true })
    end,
  },
}

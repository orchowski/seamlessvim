local M = {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',
    'nvim-neotest/neotest-python',
    { 'fredrikaverpil/neotest-golang', version = '*' },
  },
  config = function()
    local neotest = require 'neotest'

    neotest.setup {
      adapters = {
        -- Python adapter
        require 'neotest-python' {
          dap = { justMyCode = false },
          args = { '--log-level', 'DEBUG' },
          runner = 'pytest',
          python = '.venv/bin/python',
          is_test_file = function(file_path)
            return file_path:match '_test%.py$' ~= nil
          end,
          pytest_discover_instances = true,
        },

        -- Go adapter
        require 'neotest-golang' {
          -- Pass build tags directly to `go test`
          go_test_args = { '-tags=integration', '-count=1', '-timeout=60s' },
          -- Alternatively, you can set them via env:
          -- env = { GOFLAGS = "-tags=integration" },
          -- Disable dap-go integration (you already have custom DAP config)
          dap_go_enabled = false,
        },
      },
      -- Optional UI tweaks
      output = { open_on_run = false },
      quickfix = { open = false },
      diagnostic = { enabled = true },
      floating = { border = 'rounded' },
      summary = { open = 'botright vsplit' },
    }

    -- ================= KEYMAPS =================
    local map = vim.keymap.set
    local desc = function(d)
      return { desc = d }
    end

    -- Run nearest test
    map('n', '<leader>tn', function()
      neotest.run.run()
    end, desc '[T]est [N]earest')
    -- Run all tests in current file
    map('n', '<leader>tf', function()
      neotest.run.run(vim.fn.expand '%')
    end, desc '[T]est [F]ile')
    -- Debug nearest test using DAP
    map('n', '<leader>td', function()
      neotest.run.run { strategy = 'dap' }
    end, desc '[T]est [D]ebug')
    -- Toggle summary panel
    map('n', '<leader>ts', function()
      neotest.summary.toggle()
    end, desc '[T]est [S]ummary')
    -- Show output of last run
    map('n', '<leader>to', function()
      neotest.output.open { enter = true }
    end, desc '[T]est [O]utput')
    -- Toggle output panel
    map('n', '<leader>tp', function()
      neotest.output_panel.toggle()
    end, desc '[T]est [P]anel')
    -- Toggle watch for nearest test
    map('n', '<leader>tw', function()
      neotest.watch.toggle()
    end, desc '[T]est [W]atch nearest')
    -- Toggle watch for current file
    map('n', '<leader>tW', function()
      neotest.watch.toggle(vim.fn.expand '%')
    end, desc '[T]est [W]atch file')
    -- Run all tests in the project (using current working directory)
    vim.keymap.set('n', '<leader>ta', function()
      require('neotest').run.run(vim.loop.cwd())
    end, { desc = '[T]est [A]ll project' })
    -- Auto-open output if a test fails
    vim.api.nvim_create_autocmd('User', {
      pattern = 'NeotestRun',
      callback = function(data)
        local client_id = data.data and data.data.client_id
        local results = client_id and require('neotest.client').get_results(client_id) or nil
        if results then
          for _, r in pairs(results) do
            if r.status == 'failed' then
              neotest.output.open { enter = false, last_run = true }
              break
            end
          end
        end
      end,
    })
  end,
}

return M

-- neotest: run tests for Go, Python, Java/Kotlin/Groovy, JS/TS, PHP, C/C++.
--
-- Adapter order matters when several claim the same file:
--   * neotest-java matches by class stem (`*Test`/`*Spec`), so its is_test_file
--     is patched to leave Groovy/Spock specs to the gradle adapter.
--   * neotest-vitest only claims JS test files in vitest projects; neotest-jest
--     takes everything else (jest projects, or projects without a runner config).

return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
    'nvim-neotest/neotest-python',
    { 'fredrikaverpil/neotest-golang', version = '*' },
    'rcasia/neotest-java',
    'weilbith/neotest-gradle',
    'nvim-neotest/neotest-jest',
    'marilari88/neotest-vitest',
    'olimorris/neotest-phpunit',
    'alfaix/neotest-gtest',
  },
  keys = {
    { '<leader>tn', desc = '[T]est [N]earest' },
    { '<leader>tf', desc = '[T]est [F]ile' },
    { '<leader>td', desc = '[T]est [D]ebug' },
    { '<leader>ts', desc = '[T]est [S]ummary' },
    { '<leader>to', desc = '[T]est [O]utput' },
    { '<leader>tp', desc = '[T]est [P]anel' },
    { '<leader>tw', desc = '[T]est [W]atch nearest' },
    { '<leader>tW', desc = '[T]est [W]atch file' },
    { '<leader>ta', desc = '[T]est [A]ll project' },
  },
  config = function()
    local neotest = require 'neotest'
    local goTestTags = '--tags=integration,unit'

    -- neotest-java matches test files by class stem (`*Test`/`*Spec`) regardless
    -- of extension, so it would also claim Groovy/Spock specs and e.g. PHP
    -- `*Test.php`. Restrict it to Java files; the gradle adapter handles
    -- Groovy/Kotlin.
    local java_adapter = require 'neotest-java' {}
    local java_is_test_file = java_adapter.is_test_file
    java_adapter.is_test_file = function(path)
      if not path:match '%.java$' then
        return false
      end
      return java_is_test_file(path)
    end

    local function is_js_test(path)
      return path:match '%.[jt]sx?$' ~= nil and (path:match '%.test%.[jt]sx?$' or path:match '%.spec%.[jt]sx?$')
    end

    local function root_has(path, markers)
      return vim.fs.root(path, markers) ~= nil
    end

    neotest.setup {
      adapters = {
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

        require 'neotest-golang' {
          go_test_args = { goTestTags, '-count=1', '-timeout=60s' },
          env = { GOFLAGS = goTestTags },
          -- Disable dap-go integration (custom DAP config lives in dap.lua)
          dap_go_enabled = false,
        },

        -- Java (JUnit 5) via Maven/Gradle
        java_adapter,

        -- Java/Kotlin + Groovy/Spock via Gradle (patched for Spock)
        require 'util.neotest_gradle_spock'(),

        -- Vitest only when the project actually uses it, so it never shadows jest.
        require 'neotest-vitest' {
          is_test_file = function(path)
            return is_js_test(path)
              and root_has(path, {
                'vitest.config.ts',
                'vitest.config.js',
                'vitest.config.mts',
                'vitest.config.mjs',
                'vitest.workspace.ts',
                'vitest.workspace.js',
              })
          end,
        },

        -- Jest (and JS test files in projects without a vitest config)
        require 'neotest-jest' {
          isTestFile = function(path)
            return is_js_test(path)
              and not root_has(path, {
                'vitest.config.ts',
                'vitest.config.js',
                'vitest.config.mts',
                'vitest.config.mjs',
                'vitest.workspace.ts',
                'vitest.workspace.js',
              })
          end,
        },

        require 'neotest-phpunit',

        require('neotest-gtest').setup {},
      },

      output = { open_on_run = false },
      quickfix = { open = false },
      diagnostic = { enabled = true },
      floating = { border = 'rounded' },
      summary = { open = 'botright vsplit' },
      consumers = {
        -- Auto-open the output panel when a run left failing tests.
        -- (The previous config used a `User NeotestRun` autocmd; neotest no
        -- longer emits that, listeners are the supported hook.)
        open_output_on_failure = function(client)
          client.listeners.results = function(_, results, partial)
            if partial then
              return
            end
            for _, r in pairs(results) do
              if r.status == 'failed' then
                require('neotest').output.open { enter = false, last_run = true }
                break
              end
            end
          end
        end,
      },
    }

    -- ================= KEYMAPS =================
    local map = vim.keymap.set

    map('n', '<leader>tn', function()
      neotest.run.run()
    end, { desc = '[T]est [N]earest' })
    map('n', '<leader>tf', function()
      neotest.run.run(vim.fn.expand '%')
    end, { desc = '[T]est [F]ile' })
    map('n', '<leader>td', function()
      neotest.run.run { strategy = 'dap' }
    end, { desc = '[T]est [D]ebug' })
    map('n', '<leader>ts', function()
      neotest.summary.toggle()
    end, { desc = '[T]est [S]ummary' })
    map('n', '<leader>to', function()
      neotest.output.open { enter = true }
    end, { desc = '[T]est [O]utput' })
    map('n', '<leader>tp', function()
      neotest.output_panel.toggle()
    end, { desc = '[T]est [P]anel' })
    map('n', '<leader>tw', function()
      neotest.watch.toggle()
    end, { desc = '[T]est [W]atch nearest' })
    map('n', '<leader>tW', function()
      neotest.watch.toggle(vim.fn.expand '%')
    end, { desc = '[T]est [W]atch file' })
    map('n', '<leader>ta', function()
      neotest.run.run(vim.uv.cwd())
    end, { desc = '[T]est [A]ll project' })
  end,
}

-- Debugger: nvim-dap + dap-ui, adapters installed through mason.
--
-- Custom launch configurations per language:
--   Go  -> inline below (ported from the previous custom debug config)
--   PHP -> inline below (Docker/Xdebug setups)
--   Java/Kotlin/Scala -> owned by their LSP plugins (lua/plugins/lang/*)

return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'mason-org/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',
    'leoluz/nvim-dap-go',
  },
  keys = {
    {
      '<F5>',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Start/Continue',
    },
    {
      '<F1>',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<F2>',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<F3>',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    {
      '<leader>b',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<leader>B',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Debug: Set Breakpoint',
    },
    {
      '<F7>',
      function()
        require('dapui').toggle()
      end,
      desc = 'Debug: See last session result.',
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    -- DAP adapters installed only when their runtime exists. Adapter names are
    -- nvim-dap source names (mason-nvim-dap maps them to mason packages).
    -- Adapter packages are installed by mason-tool-installer (see lsp.lua);
    -- mason-nvim-dap just wires up the default adapter configurations for every
    -- installed adapter.
    require('mason-nvim-dap').setup {
      automatic_installation = false,
      handlers = {},
      ensure_installed = {},
    }

    dapui.setup {
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
    vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
    local breakpoint_icons = vim.g.have_nerd_font and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
      or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
    for type, icon in pairs(breakpoint_icons) do
      local tp = 'Dap' .. type
      local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
      vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
    end

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- ===================== Go =====================
    require('dap-go').setup {
      delve = {
        -- On Windows delve must be run attached or it crashes.
        detached = vim.fn.has 'win32' == 0,
        buildFlags = { '-tags=unit,integration' },
      },
    }
    dap.configurations.go = vim.list_extend({
      {
        type = 'go',
        name = 'MY Debug main in ./cmd',
        request = 'launch',
        program = '${workspaceFolder}/cmd',
      },
      {
        type = 'go',
        name = 'MY Debug main in ./',
        request = 'launch',
        program = '${workspaceFolder}/',
      },
      {
        type = 'go',
        name = 'MY Debug file',
        request = 'launch',
        program = '${file}',
      },
      {
        type = 'go',
        name = 'MY Debug module',
        request = 'launch',
        program = '${fileDirName}',
      },
      {
        type = 'go',
        name = 'MY Debug test under cursor',
        request = 'launch',
        mode = 'test',
        program = '${fileDirname}',
        args = function()
          local line = vim.fn.getline '.'
          local name = line:match '^func%s+(Test%w+)'
          if name then
            return { '-test.run', name }
          else
            print 'Brak testu pod kursorem'
            return {}
          end
        end,
      },
    }, dap.configurations.go or {})
    for _, cfg in ipairs(dap.configurations.go) do
      if string.find(cfg.name, 'MY') then
        cfg.buildFlags = { '-tags=integration,unit' }
      else
        cfg.name = 'DEFAULT: ' .. cfg.name
      end
    end

    -- ===================== PHP =====================
    dap.adapters.php = {
      type = 'executable',
      command = 'node',
      args = { vim.fn.stdpath 'data' .. '/mason/packages/php-debug-adapter/extension/out/phpDebug.js' },
    }

    dap.configurations.php = vim.list_extend({
      {
        type = 'php',
        name = 'MY Listen for Xdebug (Docker)',
        request = 'launch',
        port = 9000,
        pathMappings = {
          ['/var/www/html'] = '${workspaceFolder}',
        },
        log = true,
        logFile = vim.fn.stdpath 'cache' .. '/dap-php.log',
      },
      {
        type = 'php',
        name = 'MY Debug current file (CLI)',
        request = 'launch',
        port = 9003,
        cwd = '${workspaceFolder}',
        program = '${file}',
        runtimeExecutable = 'docker-compose',
        runtimeArgs = {
          'exec',
          '-T',
          'web',
          'php',
        },
        pathMappings = {
          ['/var/www/html'] = '${workspaceFolder}',
        },
      },
      {
        type = 'php',
        name = 'MY Debug PHPUnit current file',
        request = 'launch',
        port = 9003,
        cwd = '${workspaceFolder}',
        runtimeExecutable = 'docker-compose',
        runtimeArgs = {
          'exec',
          '-T',
          'web',
          'vendor/bin/phpunit',
          '${file}',
        },
        pathMappings = {
          ['/var/www/html'] = '${workspaceFolder}',
        },
      },
      {
        type = 'php',
        name = 'MY Debug PHPUnit test under cursor',
        request = 'launch',
        port = 9003,
        cwd = '${workspaceFolder}',
        runtimeExecutable = 'docker-compose',
        runtimeArgs = function()
          local line = vim.fn.getline '.'
          local test_name = line:match 'function%s+(test%w+)'

          if test_name then
            return {
              'exec',
              '-T',
              'web',
              'vendor/bin/phpunit',
              '--filter',
              test_name,
              '${file}',
            }
          else
            print 'Brak testu pod kursorem'
            return {
              'exec',
              '-T',
              'web',
              'vendor/bin/phpunit',
              '${file}',
            }
          end
        end,
        pathMappings = {
          ['/var/www/html'] = '${workspaceFolder}',
        },
      },
    }, dap.configurations.php or {})

    for _, cfg in ipairs(dap.configurations.php) do
      if not string.find(cfg.name, 'MY') then
        cfg.name = 'DEFAULT: ' .. cfg.name
      end
    end
    -- ===================== Python =====================
    -- debugpy launches the debuggee with the interpreter from the `python`
    -- field. Resolve the project's interpreter so dependencies from the venv
    -- are visible (activated VIRTUAL_ENV/CONDA_PREFIX, or a .venv/venv/env
    -- directory in the project root). The project root is put on PYTHONPATH and
    -- used as cwd. If the file lives inside a package (i.e. the top-level dir
    -- under the root has an __init__.py), it is run as a module (`python -m
    -- pkg.mod`) so relative imports and `import <top_level_package>` work.
    local function python_root()
      return vim.fs.root(0, { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' }) or vim.fn.getcwd()
    end

    local function python_executable()
      local suffix = vim.fn.has 'win32' == 1 and '/Scripts/python.exe' or '/bin/python'
      local function exists(path)
        return path and vim.uv.fs_stat(path) ~= nil
      end
      for _, var in ipairs { 'VIRTUAL_ENV', 'CONDA_PREFIX' } do
        local base = os.getenv(var)
        if base and exists(base .. suffix) then
          return base .. suffix
        end
      end
      local root = python_root()
      for _, name in ipairs { '.venv', 'venv', 'env' } do
        if exists(root .. '/' .. name .. suffix) then
          return root .. '/' .. name .. suffix
        end
      end
      local sys = vim.fn.exepath 'python3'
      return sys ~= '' and sys or nil
    end

    -- Dotted module path when the current file belongs to a package, else nil.
    local function python_module()
      local file = vim.fn.expand '%:p'
      local root = python_root()
      if file == '' or not vim.startswith(file, root) then
        return nil
      end
      local rel = file:sub(#root + 1):gsub('^/', ''):gsub('%.py$', '')
      local top = rel:match '^([^/]+)/'
      if top and vim.uv.fs_stat(root .. '/' .. top .. '/__init__.py') then
        return (rel:gsub('/', '.'))
      end
      return nil
    end

    dap.configurations.python = {
      {
        type = 'python',
        request = 'launch',
        name = 'Launch file',
        -- exactly one of program/module is set (nvim-dap drops nil results)
        program = function()
          if python_module() then
            return nil
          end
          return vim.fn.expand '%:p'
        end,
        module = python_module,
        python = python_executable,
        cwd = python_root,
        env = function()
          return { PYTHONPATH = python_root() }
        end,
        console = 'integratedTerminal',
      },
    }

    -- ===================== Node / TS =====================
    -- mason-nvim-dap does not map the `js` adapter to `pwa-node`, so it is
    -- wired up here (js-debug-adapter comes from mason).
    dap.adapters['pwa-node'] = {
      type = 'server',
      host = 'localhost',
      port = '${port}',
      executable = {
        command = 'node',
        args = {
          vim.fn.stdpath 'data' .. '/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js',
          '${port}',
        },
      },
    }

    for _, language in ipairs { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' } do
      dap.configurations[language] = {
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Launch file',
          program = '${file}',
          cwd = '${workspaceFolder}',
          sourceMaps = true,
          protocol = 'inspector',
          console = 'integratedTerminal',
        },
        {
          type = 'pwa-node',
          request = 'attach',
          name = 'Attach to process',
          processId = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}',
        },
      }
    end

    -- ===================== C / C++ =====================
    local codelldb_config = {
      {
        type = 'codelldb',
        request = 'launch',
        name = 'Launch file',
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
      },
    }
    dap.configurations.c = codelldb_config
    dap.configurations.cpp = codelldb_config
  end,
}

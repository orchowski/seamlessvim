-- Java: nvim-jdtls owns the eclipse.jdt.ls client (workspace/configuration,
-- progress handlers, code lenses) which the bare lspconfig client lacks.
-- DAP + JUnit support come from the java-debug-adapter / java-test bundles.

return {
  'mfussenegger/nvim-jdtls',
  ft = 'java',
  dependencies = {
    'mason-org/mason.nvim',
    'mfussenegger/nvim-dap',
  },
  config = function()
    local jdtls = require 'jdtls'

    local root = require('jdtls.setup').find_root {
      '.git',
      'mvnw',
      'gradlew',
      'pom.xml',
      'build.gradle',
      'settings.gradle',
    }
    if not root then
      vim.notify('nvim-jdtls: nie znaleziono katalogu projektu (pom.xml/build.gradle/.git)', vim.log.levels.WARN)
      return
    end

    -- Separate eclipse workspace per project so projects don't clash.
    local workspace_dir = vim.fn.stdpath 'cache' .. '/jdtls/' .. vim.fn.fnamemodify(root, ':t')

    -- Bundles add functionality: java-debug-adapter (debugging) and java-test (JUnit).
    local mason = vim.fn.stdpath 'data' .. '/mason/packages'
    local function glob(pattern)
      return vim.split(vim.fn.glob(pattern, true), '\n', { trimempty = true })
    end
    local bundles = {}
    vim.list_extend(bundles, glob(mason .. '/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar'))
    vim.list_extend(bundles, glob(mason .. '/java-test/extension/server/*.jar'))

    local config = {
      cmd = { 'jdtls', '-data', workspace_dir },
      root_dir = root,
      init_options = { bundles = bundles },
      settings = {
        java = {
          eclipse = { downloadSources = true },
          maven = { downloadSources = true },
          referencesCodeLens = { enabled = true },
          implementationsCodeLens = { enabled = true },
          signatureHelp = { enabled = true },
          completion = {
            favoriteStaticMembers = {
              'org.junit.jupiter.api.Assertions.*',
              'org.junit.jupiter.api.Assumptions.*',
              'org.mockito.Mockito.*',
              'org.mockito.ArgumentMatchers.*',
              'java.util.Objects.requireNonNull',
            },
            importOrder = { 'java', 'javax', 'com', 'org' },
          },
        },
      },
      on_attach = function(_, bufnr)
        local map = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'Java: ' .. desc })
        end
        map('<leader>co', jdtls.organize_imports, 'Organize Imports')
        map('<leader>cv', jdtls.extract_variable, 'Extract Variable')
        map('<leader>cc', jdtls.extract_constant, 'Extract Constant')
        map('<leader>cm', function()
          jdtls.extract_method(true)
        end, 'Extract Method')
      end,
    }

    jdtls.start_or_attach(config)

    -- Wire eclipse.jdt.ls into nvim-dap via the java-debug-adapter bundle.
    jdtls.setup_dap { hotcodereplace = 'auto' }
    local dap = require 'dap'
    dap.configurations.java = vim.list_extend({
      {
        type = 'java',
        request = 'launch',
        name = 'Debug (Launch) - Current File',
        mainClass = '${file}',
      },
      {
        type = 'java',
        request = 'launch',
        name = 'Debug (Launch) - Main Class',
        mainClass = function()
          return vim.fn.input 'Main class: '
        end,
      },
      {
        type = 'java',
        request = 'attach',
        name = 'Debug (Attach) - Remote',
        hostName = '127.0.0.1',
        port = 5005,
      },
    }, dap.configurations.java or {})
  end,
}

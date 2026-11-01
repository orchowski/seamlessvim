-- LSP core: installation (mason), server configs, LspAttach keymaps, diagnostics.
--
-- Servers owned by a dedicated plugin are configured elsewhere and must NOT be
-- enabled here:
--   jdtls        -> lua/plugins/lang/java.lua   (nvim-jdtls)
--   kotlin_lsp   -> lua/plugins/lang/kotlin.lua (kotlin.nvim)
--   metals       -> lua/plugins/lang/scala.lua  (nvim-metals)

return {
  { 'folke/lazydev.nvim', ft = 'lua', opts = { library = { { path = '${3rd}/luv/library', words = { 'vim%.uv' } } } } },

  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      'saghen/blink.cmp',
    },
    config = function()
      -- Completion capabilities for every client (also vim.lsp.start()-based ones).
      vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities() })

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('seamlessvim-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('gtR', vim.lsp.buf.rename, '[R]e[n]ame')
          map('gta', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('gtr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
          map('gti', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
          map('gtd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
          map('gtD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          map('gO', require('telescope.builtin').lsp_document_symbols, 'Open Document Symbols')
          map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')
          map('gtt', require('telescope.builtin').lsp_type_definitions, '[G]oto [T]ype Definition')

          local client = vim.lsp.get_client_by_id(event.data.client_id)

          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup('seamlessvim-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('seamlessvim-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'seamlessvim-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end

          if client and client.name == 'groovyls' then
            require('util.groovyls_classpath').attach(event.buf)
          end
        end,
      })

      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = {
          source = 'if_many',
          spacing = 2,
          format = function(diagnostic)
            local diagnostic_message = {
              [vim.diagnostic.severity.ERROR] = diagnostic.message,
              [vim.diagnostic.severity.WARN] = diagnostic.message,
              [vim.diagnostic.severity.INFO] = diagnostic.message,
              [vim.diagnostic.severity.HINT] = diagnostic.message,
            }
            return diagnostic_message[diagnostic.severity]
          end,
        },
      }

      local servers = {
        gopls = {
          cmd = { 'gopls', '-rpc.trace', '-logfile', vim.fn.stdpath 'cache' .. '/gopls.log' },
          cmd_env = { GOFLAGS = '-tags=integration' },
          settings = {
            gopls = {
              completeUnimported = true,
              usePlaceholders = true,
              analyses = {
                unusedparams = true,
                unusedvariables = true,
                fillstruct = true,
              },
              buildFlags = { '-tags=integration' },
            },
          },
        },
        jedi_language_server = {},
        vtsls = {},
        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
            },
          },
        },
        groovyls = {},
        clojure_lsp = {},
        clangd = {},
        phpactor = {
          -- PHP formatting stays off (see format_on_save exclusions in formatting.lua).
          on_attach = function(client, _)
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end,
        },
      }

      -- Skip servers whose system runtime is missing so mason never errors on
      -- machines without that toolchain.
      local server_runtime_requirements = {
        gopls = { 'go' },
        jedi_language_server = { 'python3' },
        vtsls = { 'node' },
        groovyls = { 'java' },
        phpactor = { 'php', 'composer' },
      }
      for server_name, runtimes in pairs(server_runtime_requirements) do
        for _, runtime in ipairs(runtimes) do
          if vim.fn.executable(runtime) == 0 then
            servers[server_name] = nil
            break
          end
        end
      end

      -- Everything mason should install: language servers plus tools that are
      -- launched by plugins or used by conform/mason-nvim-dap.
      local mason_tools = {
        -- language servers (started via vim.lsp.enable below)
        'clangd',
        'clojure-lsp',
        'gopls',
        'groovy-language-server',
        'jedi-language-server',
        'lua-language-server',
        'phpactor',
        'vtsls',
        -- language servers launched by their own plugin (see lua/plugins/lang/)
        'jdtls',
        'kotlin-lsp',
        -- formatters (see formatting.lua)
        'stylua',
        'black',
        'isort',
        'shfmt',
        'prettierd',
        'prettier',
        'taplo',
        'gofumpt',
        'goimports',
        'google-java-format',
        'ktlint',
        'clang-format',
        'php-cs-fixer',
        'pint',
        -- linters
        'markdownlint-cli2',
        -- debug adapters (configured by mason-nvim-dap in dap.lua)
        'codelldb',
        'delve',
        'debugpy',
        'js-debug-adapter',
        'java-debug-adapter',
        'java-test',
        'php-debug-adapter',
      }
      local tool_runtime_requirements = {
        ['groovy-language-server'] = { 'java' },
        ['jdtls'] = { 'java' },
        ['google-java-format'] = { 'java' },
        ['ktlint'] = { 'java' },
        ['black'] = { 'python3' },
        ['isort'] = { 'python3' },
        ['jedi-language-server'] = { 'python3' },
        ['gopls'] = { 'go' },
        ['gofumpt'] = { 'go' },
        ['goimports'] = { 'go' },
        ['phpactor'] = { 'php', 'composer' },
        ['php-cs-fixer'] = { 'php' },
        ['pint'] = { 'php' },
        ['prettier'] = { 'node' },
        ['prettierd'] = { 'node' },
        ['vtsls'] = { 'node' },
        -- debug adapters
        ['delve'] = { 'go' },
        ['debugpy'] = { 'python3' },
        ['js-debug-adapter'] = { 'node' },
        ['java-debug-adapter'] = { 'java' },
        ['java-test'] = { 'java' },
        ['php-debug-adapter'] = { 'php', 'node' },
      }
      local ensure_installed = {}
      for _, tool in ipairs(mason_tools) do
        local runtimes = tool_runtime_requirements[tool]
        local can_install = true
        for _, runtime in ipairs(runtimes or {}) do
          if vim.fn.executable(runtime) == 0 then
            can_install = false
            break
          end
        end
        if can_install then
          table.insert(ensure_installed, tool)
        end
      end
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      -- mason-lspconfig v2: no handlers, no require('lspconfig').setup().
      -- Configure first, enable second; automatic_enable stays off so only the
      -- servers in `servers` start (with the overrides above applied).
      require('mason-lspconfig').setup {
        ensure_installed = {},
        automatic_enable = false,
      }

      for server_name, server in pairs(servers) do
        vim.lsp.config(server_name, server)
        vim.lsp.enable(server_name)
      end
    end,
  },
}

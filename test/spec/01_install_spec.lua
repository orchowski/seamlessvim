-- Verifies external tools, mason packages and treesitter parsers are installed.

local H = dofile(vim.fn.stdpath 'config' .. '/test/spec/helpers.lua')

describe('external tools', function()
  local bins = {
    'git',
    'rg',
    'fd',
    'fzf',
    'make',
    'gcc',
    'unzip',
    'curl',
    'node',
    'npm',
    'go',
    'java',
    'php',
    'composer',
    'python3',
    'clojure',
    'tree-sitter',
    'cs',
  }
  for _, bin in ipairs(bins) do
    it('has ' .. bin .. ' on PATH', function()
      assert(vim.fn.executable(bin) == 1, bin .. ' not found on PATH')
    end)
  end

  it('tree-sitter CLI is >= 0.26', function()
    local out = vim.fn.system { 'tree-sitter', '--version' }
    local ver = out:match '%d+%.%d+%.%d+'
    assert(ver, 'could not parse tree-sitter version: ' .. out)
    local major, minor = ver:match '^(%d+)%.(%d+)'
    assert(tonumber(major) > 0 or tonumber(minor) >= 26, 'tree-sitter too old: ' .. ver)
  end)
end)

describe('mason packages', function()
  local mason = vim.fn.stdpath 'data' .. '/mason/packages'
  local expected = {
    -- language servers
    'clangd',
    'clojure-lsp',
    'gopls',
    'groovy-language-server',
    'jedi-language-server',
    'lua-language-server',
    'phpactor',
    'vtsls',
    'jdtls',
    'kotlin-lsp',
    -- formatters / linters
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
    'markdownlint-cli2',
    -- debug adapters
    'delve',
    'debugpy',
    'js-debug-adapter',
    'java-debug-adapter',
    'java-test',
    'codelldb',
    'php-debug-adapter',
  }
  for _, pkg in ipairs(expected) do
    it('installed: ' .. pkg, function()
      assert(vim.uv.fs_stat(mason .. '/' .. pkg) ~= nil, 'mason package missing: ' .. pkg)
    end)
  end
end)

describe('coursier tools (scala)', function()
  it('metals is available', function()
    local ok = vim.fn.executable 'metals' == 1
    if not ok then
      local alt = vim.fn.expand '~/.local/share/coursier/bin/metals'
      ok = vim.uv.fs_stat(alt) ~= nil
    end
    assert(ok, 'metals not installed (cs install metals)')
  end)
end)

describe('treesitter parsers', function()
  it('all parsers in config.parsers are installed', function()
    local installed = {}
    for _, p in ipairs(require('nvim-treesitter').get_installed 'parsers') do
      installed[p] = true
    end
    local missing = {}
    for _, p in ipairs(require 'config.parsers') do
      if not installed[p] then
        table.insert(missing, p)
      end
    end
    assert(#missing == 0, 'missing parsers: ' .. table.concat(missing, ', '))
  end)
end)

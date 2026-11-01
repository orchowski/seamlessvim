-- :checkhealth config — verifies external tools the config expects.
local M = {}

local check = vim.health or require 'health'
local start = check.start or check.report_start
local ok = check.ok or check.report_ok
local warn = check.warn or check.report_warn
local error_ = check.error or check.report_error

local function has(bin)
  return vim.fn.executable(bin) == 1
end

local function check_bin(bin, level, hint)
  if has(bin) then
    ok('`' .. bin .. '` found: ' .. vim.fn.exepath(bin))
  else
    (level == 'error' and error_ or warn)('`' .. bin .. '` not found' .. (hint and (' — ' .. hint) or ''))
  end
end

function M.check()
  start 'seamlessvim: core tools'
  check_bin('git', 'error', 'required for lazy.nvim')
  check_bin('rg', 'error', 'required by telescope live_grep: pacman -S ripgrep / apt install ripgrep / brew install ripgrep')
  check_bin('fd', 'warn', 'used by telescope find_files: pacman -S fd / apt install fd-find / brew install fd')
  check_bin('make', 'warn', 'builds telescope-fzf-native and LuaSnip jsregexp')
  check_bin('gcc', 'warn', 'builds telescope-fzf-native and LuaSnip jsregexp')
  check_bin('unzip', 'warn', 'required by mason.nvim')
  if vim.fn.has 'nvim-0.11' == 1 then
    ok 'Neovim >= 0.11 (vim.lsp.config / vim.lsp.enable available)'
  else
    error_ 'Neovim 0.11+ required (mason-lspconfig v2, vim.lsp.config)'
  end

  start 'seamlessvim: language runtimes (gates LSP/debugger installs)'
  check_bin('go', 'warn', 'enables gopls + delve + neotest-golang')
  check_bin('java', 'warn', 'enables jdtls/kotlin/groovy/gradle LSP + java debug')
  check_bin('python3', 'warn', 'enables jedi_language_server + debugpy')
  check_bin('node', 'warn', 'enables vtsls + js-debug-adapter + php-debug-adapter')
  check_bin('php', 'warn', 'enables phpactor + php-debug-adapter')
  check_bin('composer', 'warn', 'required by phpactor')
  check_bin(
    'cs',
    'warn',
    'coursier — needed once for metals/scalafmt (Scala): curl -fL https://github.com/coursier/launchers/raw/master/cs-x86_64-pc-linux.gz | gzip -d > cs && chmod +x cs'
  )
end

return M

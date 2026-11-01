-- Verifies each language server attaches to a fixture, and that the LSP
-- buffer-local keymaps are registered on attach.

local H = dofile(vim.fn.stdpath 'config' .. '/test/spec/helpers.lua')

-- Language servers may raise blocking prompts (e.g. clojure-lsp asking which
-- classpath tool to use). Auto-answer with "Ignore"/first option so the suite
-- never hangs in headless mode.
vim.ui.select = function(items, _, on_choice)
  local choice = items[1]
  for _, it in ipairs(items) do
    if tostring(it):lower():find 'ignore' then
      choice = it
    end
  end
  on_choice(choice, 1)
end
vim.ui.input = function(_, on_confirm)
  on_confirm ''
end

local stacks = {
  { name = 'lua', file = 'lua/foo.lua', client = 'lua_ls', timeout = 60000 },
  { name = 'go', file = 'go/hello.go', client = 'gopls', timeout = 60000 },
  { name = 'python', file = 'python/hello_test.py', client = 'jedi_language_server', timeout = 60000 },
  { name = 'typescript', file = 'ts/index.ts', client = 'vtsls', timeout = 60000 },
  { name = 'php', file = 'php/src/Adder.php', client = 'phpactor', timeout = 60000 },
  { name = 'c', file = 'c/hello.c', client = 'clangd', timeout = 60000 },
  { name = 'clojure', file = 'clojure/core.clj', client = 'clojure_lsp', timeout = 240000 },
  { name = 'groovy', file = 'groovy/src/test/groovy/AdderSpec.groovy', client = 'groovyls', timeout = 60000 },
  { name = 'java', file = 'java/src/main/java/App.java', client = 'jdtls', timeout = 300000 },
  { name = 'kotlin', file = 'kotlin/src/main/kotlin/hello.kt', client = 'kotlin_lsp', timeout = 180000 },
  { name = 'scala', file = 'scala/src/main/scala/Main.scala', client = 'metals', timeout = 300000 },
}

describe('LSP attach', function()
  for _, s in ipairs(stacks) do
    it(s.name .. ' (' .. s.client .. ')', function()
      H.attach(H.fixture(s.file), s.client, s.timeout)
    end)
  end
end)

describe('LSP buffer keymaps', function()
  local buf
  it('attach gopls', function()
    H.attach(H.fixture 'go/hello.go', 'gopls', 60000)
    buf = vim.api.nvim_get_current_buf()
  end)
  for _, lhs in ipairs { 'gtR', 'gta', 'gtr', 'gti', 'gtd', 'gtD', 'gO', 'gW', 'gtt' } do
    it('buffer map ' .. lhs, function()
      assert(H.has_map('n', lhs, buf), 'missing LSP map: ' .. lhs .. ' (buffer local)')
    end)
  end
end)

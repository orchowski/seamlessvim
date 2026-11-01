-- Shared helpers for the seamlessvim spec suite.
-- Load with: local H = dofile(vim.fn.stdpath('config') .. '/test/spec/helpers.lua')

local M = {}

M.config = vim.fn.stdpath 'config'

function M.fixture(rel)
  return M.config .. '/test/fixtures/' .. rel
end

function M.termcodes(lhs)
  return vim.api.nvim_replace_termcodes(lhs, true, true, true)
end

--- True when `lhs` is mapped in `mode` (global, or buffer-local when bufnr given).
function M.has_map(mode, lhs, bufnr)
  local maps = bufnr and vim.api.nvim_buf_get_keymap(bufnr, mode) or vim.api.nvim_get_keymap(mode)
  local want = M.termcodes(lhs)
  for _, m in ipairs(maps) do
    if M.termcodes(m.lhs) == want then
      return true
    end
  end
  return false
end

--- Wait for `cond` to become true.
function M.wait(cond, timeout, message)
  local ok = vim.wait(timeout or 60000, cond, 100)
  assert(ok, (message or 'condition') .. ' (timed out after ' .. (timeout or 60000) .. 'ms)')
end

--- Open `file` and wait for the LSP client named `client` to attach.
function M.attach(file, client, timeout)
  vim.cmd.edit(file)
  M.wait(function()
    return #vim.lsp.get_clients { bufnr = vim.api.nvim_get_current_buf(), name = client } > 0
  end, timeout or 60000, 'LSP "' .. client .. '" attach for ' .. vim.fn.fnamemodify(file, ':t'))
end

--- Create a throwaway git repository with one committed + one modified file.
function M.git_fixture()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  local file = dir .. '/file.txt'
  vim.fn.writefile({ 'one', 'two', 'three' }, file)
  local git = { 'git', '-c', 'user.email=t@t', '-c', 'user.name=t' }
  vim.system({ 'git', 'init', '-q' }, { cwd = dir }):wait()
  vim.system({ 'git', 'add', '.' }, { cwd = dir }):wait()
  vim.system(vim.list_extend({ unpack(git) }, { 'commit', '-qm', 'init' }), { cwd = dir }):wait()
  vim.fn.writefile({ 'one', 'TWO', 'three' }, file)
  return file
end

return M

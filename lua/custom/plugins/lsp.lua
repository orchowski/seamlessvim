-- hide virtual text
vim.keymap.set('n', '<leader>dh', function()
  vim.diagnostic.config { virtual_text = false }
end, { desc = 'Hide diagnostic virtual text' })

-- show virtual text
vim.keymap.set('n', '<leader>ds', function()
  vim.diagnostic.config { virtual_text = true }
end, { desc = 'Show diagnostic virtual text' })

vim.api.nvim_create_user_command('SetGoBuildTags', function(opts)
  if #opts.fargs == 0 then
    print 'Usage: :SetTags <tag1> <tag2> ...'
    return
  end

  -- połącz argumenty przecinkami, jak Go tego lubi
  local tags = table.concat(opts.fargs, ',')
  local val = '-tags=' .. tags

  -- ustaw zmienną środowiskową w sesji NVim
  vim.fn.setenv('GOFLAGS', val)
  print('GOFLAGS set to: ' .. val)

  -- zrestartuj gopls żeby łyknął nowe flagi
  vim.cmd 'LspRestart'
end, {
  nargs = '+', -- wymaga co najmniej jednego argumentu
  complete = function()
    -- podpowiedzi, możesz tu dopisać swoje
    return { 'unit', 'integration', 'e2e' }
  end,
})
return {}

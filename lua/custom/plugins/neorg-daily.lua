-- Funkcja do odczytania pliku konfiguracyjnego i znalezienia wartości workspace
local function readWorkspace()
  local config_path = os.getenv 'HOME' .. '/.config/nvim/lua/custom/plugins/neorg.lua'
  for line in io.lines(config_path) do
    if line:match 'default_workspace%s*=%s*".-"' then
      local workspace_name = line:match 'default_workspace%s*=%s*"(.+)"'
      for line in io.lines(config_path) do
        if line:match 'workspaces%s*=%s*{' then
          for line in io.lines(config_path) do
            if line:match(workspace_name .. '%s*=%s*".-"') then
              return line:match(workspace_name .. '%s*=%s*"(.-)"')
            end
          end
        end
      end
    end
  end
  return nil
end

-- Funkcja do przeszukania katalogu i znalezienia plików .norg
local function znajdzPliki(workspace_path)
  local daily_path = workspace_path .. '/daily'
  local files = {}
  local p = io.popen('find "' .. daily_path .. '" -type f')
  for file in p:lines() do
    if file:match '%d%d%-%d%d%-%d%d%d%d.norg' then
      table.insert(files, file)
    end
  end
  p:close()
  table.sort(files, function(a, b)
    return a > b
  end) -- Sortowanie wg daty
  return files
end

-- Funkcja do tworzenia pliku dailies.norg
local function utworzDailies(files, workspace_path)
  local dailies_path = workspace_path .. '/dailies.norg'
  local file = io.open(dailies_path, 'w')

  local current_year = nil
  local current_month = nil
  for _, full_path in ipairs(files) do
    local _, _, day, month, year = full_path:find '(%d%d)%-(%d%d)%-(%d%d%d%d).norg'

    if year ~= current_year then
      file:write('* ' .. year .. '\n')
      current_year = year
    end
    if month ~= current_month then
      if current_month ~= nil then
        file:write '\n' -- Dodaje nową linię przed nowym miesiącem
      end
      file:write('** ' .. month .. '\n')
      current_month = month
    end
    file:write('- {:daily/' .. day .. '-' .. month .. '-' .. year .. ':}\n')
  end

  file:close()
  vim.api.nvim_command('edit! ' .. dailies_path)
end

-- Główna funkcja
local function dailySummary()
  local workspace_path = readWorkspace()
  if not workspace_path then
    print 'Nie znaleziono workspace w konfiguracji Neorg.'
    return
  end
  workspace_path = workspace_path:gsub('~', os.getenv 'HOME') -- zamień ~ na ścieżkę do katalogu domowego

  local files = znajdzPliki(workspace_path)
  utworzDailies(files, workspace_path)
  print('Plik dailies.norg został utworzony w ' .. workspace_path)
end

local function DailyToday()
  local workspace_path = readWorkspace()
  if not workspace_path then
    print 'Nie znaleziono workspace w konfiguracji Neorg.'
    return
  end
  workspace_path = workspace_path:gsub('~', os.getenv 'HOME') -- zamień ~ na ścieżkę do katalogu domowego

  local daily_path = workspace_path .. '/daily'
  local today = os.date '%d-%m-%Y'
  local today_file_path = daily_path .. '/' .. today .. '.norg'

  -- Sprawdź, czy plik już istnieje
  local file_exists = io.open(today_file_path, 'r')
  if not file_exists then
    -- Plik nie istnieje, więc go tworzymy i zapisujemy podstawową treść
    local file = io.open(today_file_path, 'w')
    if file then
      file:write('#+TITLE: Daily Notes for ' .. today .. '\n\n')
      file:close()
    end
  else
    -- Plik już istnieje, więc go tylko zamknij
    file_exists:close()
  end

  dailySummary()
  -- Otwórz plik w nowym buforze Neovim
  vim.api.nvim_command('edit ' .. today_file_path)
end

vim.api.nvim_create_user_command('DailyToday', DailyToday, {})
vim.api.nvim_create_user_command('DailySummary', dailySummary, {})
return {}

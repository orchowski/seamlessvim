-- Feeds groovy-language-server a usable classpath so it can resolve project
-- classes and dependencies instead of warning "unable to resolve class ...".
--
-- IMPORTANT: groovyls only understands .jar classpath entries; it silently
-- ignores class directories (net/prominic/groovyls/…/CompilationUnitFactory
-- filters entries to *.jar). So we (1) build the module's `jar` task and
-- (2) pass its build/libs directory plus every dependency jar. The classpath is
-- pushed to the running client via workspace/didChangeConfiguration.

local M = {}

local cache_dir = vim.fn.stdpath 'cache' .. '/groovy-lsp'
vim.fn.mkdir(cache_dir, 'p')

local init_script = cache_dir .. '/classpath.init.gradle'
local init_script_content = [[
allprojects { p ->
  p.afterEvaluate {
    try {
      if (p.plugins.hasPlugin('groovy') || p.plugins.hasPlugin('java')) {
        p.tasks.register('nvimGroovyClasspath') {
          doLast {
            println 'NVIMGROOVYCP:' + p.sourceSets.test.runtimeClasspath.asPath
          }
        }
      }
    } catch (Throwable ignored) {}
  }
}
]]

local function ensure_init_script()
  -- Always (re)write: the content may change between versions.
  local file = assert(io.open(init_script, 'w'))
  file:write(init_script_content)
  file:close()
  return init_script
end

local function project_root(path)
  return vim.fs.root(path, { 'build.gradle.kts', 'build.gradle', 'pom.xml', '.git' })
end

local function gradle_executable(root)
  local wrapper = vim.fs.find('gradlew', { path = root, upward = true })[1]
  return wrapper or 'gradle'
end

local running = {}

function M.attach(bufnr)
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = 'groovyls' })[1]
  if not client then
    return
  end

  local root = project_root(vim.api.nvim_buf_get_name(bufnr))
  if not root or running[root] then
    return
  end
  running[root] = true

  local gradle = gradle_executable(root)

  local function push(classpath)
    running[root] = nil
    classpath = vim.tbl_filter(function(path)
      return vim.uv.fs_stat(path) ~= nil
    end, classpath)
    if #classpath == 0 then
      return
    end
    vim.schedule(function()
      for _, c in ipairs(vim.lsp.get_clients { name = 'groovyls' }) do
        c.config.settings = c.config.settings or {}
        c.config.settings.groovy = c.config.settings.groovy or {}
        c.config.settings.groovy.classpath = classpath
        c:notify('workspace/didChangeConfiguration', { settings = c.config.settings })
      end
    end)
  end

  local function collect()
    vim.system({ gradle, '-q', '--no-configuration-cache', '-I', ensure_init_script(), 'nvimGroovyClasspath' }, { cwd = root, text = true }, function(result)
      if result.code ~= 0 then
        running[root] = nil
        return
      end

      local classpath = {}
      for line in (result.stdout or ''):gmatch '[^\n]+' do
        local path = line:match '^NVIMGROOVYCP:(.+)'
        if path then
          for _, entry in ipairs(vim.split(path, ':', { plain = true, trimempty = true })) do
            -- groovyls ignores class directories, keep only jars
            if entry:sub(-4) == '.jar' then
              table.insert(classpath, entry)
            end
          end
        end
      end

      -- The module's own classes are packaged here (built by the `jar` task);
      -- groovyls picks up the jars found inside this directory.
      local libs = root .. '/build/libs'
      if vim.uv.fs_stat(libs) then
        table.insert(classpath, libs)
      end

      push(classpath)
    end)
  end

  -- Build the module jar first (groovyls can't read class directories).
  vim.system({ gradle, '-q', '--no-configuration-cache', 'jar' }, { cwd = root, text = true }, function()
    collect()
  end)
end

return M

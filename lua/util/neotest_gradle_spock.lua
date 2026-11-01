-- Groovy/Spock support for the neotest-gradle adapter.
--
-- Upstream (weilbith/neotest-gradle) only understands Java/Kotlin: it filters
-- test files by `Test.java`/`Test.kt` and looks up treesitter position queries
-- per filetype. Spock specs are Groovy files, so this wrapper:
--   * treats `*Test.groovy`/`*Spec.groovy` as test files,
--   * adds a Groovy position query (spec class + feature methods),
--   * falls back to the standard Gradle results directory when the project
--     does not define the custom `testResultsDir` property upstream relies on.

local lib = require 'neotest.lib'

local GROOVY_TEST_FILE_PATTERNS = { 'Test%.groovy$', 'Spec%.groovy$' }

local GROOVY_POSITION_QUERY = [[
  (
    (class_definition name: (identifier) @namespace.name)
    (#match? @namespace.name "(Test|Spec)$")
  ) @namespace.definition
  (
    (function_definition
      function: (quoted_identifier (string_content) @test.name)
    ) @test.definition
  )
]]

local function find_results_directory(path)
  local project_directory = require 'neotest-gradle.hooks.find_project_directory'(path)
  if not project_directory then
    return nil
  end
  return table.concat({ project_directory, 'build', 'test-results', 'test' }, lib.files.sep)
end

return function()
  local adapter = require 'neotest-gradle'

  local upstream_is_test_file = adapter.is_test_file
  adapter.is_test_file = function(path)
    for _, pattern in ipairs(GROOVY_TEST_FILE_PATTERNS) do
      if path:match(pattern) then
        return true
      end
    end
    return upstream_is_test_file(path)
  end

  local upstream_discover_positions = adapter.discover_positions
  adapter.discover_positions = function(path)
    if path:match '%.groovy$' then
      return lib.treesitter.parse_positions(path, GROOVY_POSITION_QUERY, {
        build_position = 'require("neotest-gradle.hooks.discover_positions.build_position")',
        position_id = 'require("neotest-gradle.hooks.discover_positions.build_position_identifier")',
      })
    end
    return upstream_discover_positions(path)
  end

  local upstream_build_spec = adapter.build_spec
  adapter.build_spec = function(args)
    local spec = upstream_build_spec(args)
    if spec and spec.context then
      local dir = spec.context.test_resuls_directory
      if not dir or dir == '' or dir:match '^null' then
        spec.context.test_resuls_directory = find_results_directory(args.tree:data().path) or spec.context.test_resuls_directory
      end
    end
    return spec
  end

  return adapter
end

local lib = require("neotest.lib")
local types = require("neotest.types")
local logger = require("neotest.logging")

local jsonlist = require("neotest-moonbit.json")

local joinpath = vim.fs.joinpath
local basename = vim.fs.basename

local filetype = require("plenary.filetype")
if filetype.detect_from_extension("x.mbt") == "" then
  filetype.add_table({ extension = { mbt = "moonbit" } })
end

--- @class Adapter : neotest.Adapter
local M = {}

local MOON_MOD_JSON = "moon.mod.json"
local MOON_PKG_JSON = "moon.pkg.json"

M.Adapter = { name = "neotest-moonbit" }

---Find the project root directory given a current directory to work from.
---Should no root be found, the adapter can still be used in a non-project context if a test file matches.
---@async
---@param dir string @Directory to treat as cwd
---@return string | nil @Absolute root dir of test suite
function M.Adapter.root(dir)
  -- we want to ensure we are sitting at project root
  if dir == lib.files.match_root_pattern(MOON_MOD_JSON)(dir) then
    return dir
  end
  return nil
end

local function readJSON(path)
  local f, err = io.open(path, "r"):read("*a")
  if err then
    logger.error(err)
    return nil
  end
  local ok, json = pcall(vim.json.decode, f)
  if not ok then
    logger.error("Failed to parse " .. path)
    return nil
  end
  return json
end

---Filter directories when searching for test files
---@async
---@param name string Name of directory
---@param rel_path string Path to directory, relative to root
---@param root string Root directory of project
---@return boolean
function M.Adapter.filter_dir(name, rel_path, root)
  -- parse moon.mod.json source field
  local moon_mod_path = joinpath(root, MOON_MOD_JSON)
  local moon_mod_json = readJSON(moon_mod_path)
  if not moon_mod_json then
    return false
  end

  local source = moon_mod_json.source or "src"

  if source == rel_path then
    return true
  end
  if not vim.startswith(rel_path, source) then
    return false
  end

  -- XXX: assuming rel_path is a package path
  -- let's check if this is a main package or not
  -- at the time of writing (2024-10-28), main package can't run tests.

  local moon_pkg_path = joinpath(rel_path, MOON_PKG_JSON)
  local moon_pkg_json = readJSON(moon_pkg_path)
  if not moon_pkg_json then
    return false
  end
  return not moon_pkg_json["is-main"]
end

---@async
---@param file_path string
---@return boolean
function M.Adapter.is_test_file(file_path)
  -- packages with `is-main = false` are all valid test files
  -- which is checked in `filter_dir`
  return vim.endswith(file_path, ".mbt")
end

---Given a file path, parse all the tests within it.
---@async
---@param file_path string Absolute file path
---@return neotest.Tree | nil
function M.Adapter.discover_positions(file_path)
  local query = [[
    (test_definition
      (string_literal
        (string_fragment
          (unescaped_string_fragment) @test.name)))
      @test.definition
    ]]
  local tree = lib.treesitter.parse_positions(file_path, query, {})
  for i, child in ipairs(tree:children()) do
    local id = child:data().id
    -- currently moonbit run specific test using their test index in a file
    local splitted_id = vim.fn.split(id, "::")
    child:data().id = splitted_id[1] .. "::" .. tostring(i - 1)
  end
  return tree
end

---@param args neotest.RunArgs
---@return nil | neotest.RunSpec | neotest.RunSpec[]
function M.Adapter.build_spec(args)
  --- The tree object, describing the AST-detected tests and their positions.
  --- @type neotest.Tree
  local tree = args.tree

  if not tree then
    logger.error("Unexpectedly did not receive a neotest.Tree.")
    return
  end

  --- The position object, describing the current directory, file or test.
  --- @type neotest.Position
  local pos = tree:data()

  -- NOTE: assume cwd to be our project root for now to simplify things
  local root = vim.uv.cwd()
  local moon_mod_path = joinpath(root, MOON_MOD_JSON)
  local moon_mod_json = readJSON(moon_mod_path)
  if not moon_mod_json then
    logger.error("probably not a moonbit project root.")
    return nil
  end

  local src_path = joinpath(root, moon_mod_json.source or "src")
  local rel_path = pos.path:sub(#src_path + 2)
  local filename = basename(rel_path)
  local pkg_name = rel_path:sub(0, -(#filename + 2))
  local mod_name = moon_mod_json.name

  if pos.type == "test" then
    local splitted_pos_id = vim.fn.split(pos.id, "::")
    local test_idx = splitted_pos_id[#splitted_pos_id]

    return {
      command = { "moon", "test", "--test-failure-json", "-p", pkg_name, "-f", filename, "-i", test_idx },
      cwd = root,
      context = {
        kind = "test",
        test_idx = test_idx,
        path = pos.path,
      },
    }
  elseif pos.type == "file" then
    return {
      command = { "moon", "test", "--test-failure-json", "-p", pkg_name, "-f", filename },
      cwd = root,
      context = {
        kind = "file",
        path = pos.path,
      },
    }
  elseif pos.type == "dir" then
    return {
      command = { "moon", "test", "--test-failure-json" },
      cwd = root,
      context = {
        kind = "dir",
        path = pos.path,
        mod_name = mod_name,
        src = src_path,
      },
    }
  else
    logger.error("unknown pos.type " .. pos.type)
  end
end

---@param tree neotest.Tree
---@param results table<string, neotest.Result>
---@return table<string, neotest.Result>
local function build_results(tree, results)
  -- traverse the nested tree, and put the result
  results[tree:data().id] = { status = types.ResultStatus.passed }
  for _, child in pairs(tree:children()) do
    build_results(child, results)
  end
  return results
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
function M.Adapter.results(spec, result, tree)
  -- vim.print("=================== results")
  -- vim.print(vim.inspect(spec))
  -- vim.print(vim.inspect(result))
  -- vim.print(vim.inspect(tree:data()))
  -- vim.print("id: " .. tree:data().id)
  -- if result.code == 0 then
  --   return { [tree:data().id] = { status = types.ResultStatus.passed } }
  -- end
  local results = build_results(tree, {})

  if result.code == 0 then
    return results
  end

  local output, err = io.open(result.output, "r"):read("*a")
  if err then
    logger.error(err)
    return {}
  end

  -- print("output")
  -- print(vim.inspect(output))

  local function get_test_filepath(context, failed)
    if context.kind ~= "dir" then
      return context.path
    end
    -- for project(dir) wise result, we have to compose the path
    -- path = ctx.src + (failed.package - ctx.mod_name) + failed.filename
    return joinpath(context.src, failed.package:sub(#context.mod_name + 1), failed.filename)
  end

  local function build_id(context, res)
    return get_test_filepath(context, res) .. "::" .. res.index
  end

  local function parse_line_number(context, failed)
    local path = get_test_filepath(context, failed)
    return failed.message:match(path .. ":(%d+):")
  end

  local failure_jsons = jsonlist.decode_from_string(output)
  -- vim.print("failure_jsons: " .. #failure_jsons)
  -- vim.print(vim.inspect(failure_jsons))

  for _, failed in pairs(failure_jsons) do
    -- parse range and put it into neotest.Result
    local id = build_id(spec.context, failed)
    local line = parse_line_number(spec.context, failed)
    local message = failed.message:match("`(.+)`$") or "Test failed"
    results[id] = {
      status = types.ResultStatus.failed,
      output = result.output,
      errors = {
        {
          message = message,
          line = tonumber(line) - 1,
        },
      },
    }
  end
  -- vim.print(vim.inspect(results))
  return results
end

return M.Adapter

local base       = require("moonbit.mooncakes.api.base")
local semver     = require("moonbit.mooncakes.util.semver")
local fn         = vim.fn
local path_sep = package.config:sub(1, 1)

local M = {}
local state = { by_name = {}, flat = {}, loaded = false }

local function load_local_entries()
  local entries = {}
  local moon_home = vim.env["MOON_HOME"]
  if moon_home == nil then
    local home = vim.env["HOME"]
    if home == nil then
      home = '~'
    end
    moon_home = home .. path_sep .. '.moon'
  end
  local index_dir = fn.expand(moon_home .. path_sep .. "registry" .. path_sep .. "index" .. path_sep .. "user")
  local creators = fn.glob(index_dir .. path_sep .. "*", true, true)
  for _, creator_path in ipairs(creators) do
    local files = fn.glob(creator_path .. path_sep .. "*.index", true, true)
    for _, path in ipairs(files) do
      local fh = io.open(path, "r")
      if fh then
        for line in fh:lines() do
          if line ~= "" then
            local ok, obj = pcall(vim.json.decode, line)
            if ok and type(obj) == "table" and obj.name and obj.version then
              table.insert(entries, obj)
            end
          end
        end
        fh:close()
      end
    end
  end
  return entries
end

local function ensure_index()
  if not state.loaded then
    local entries = load_local_entries()
    state.by_name, state.flat = base.build_index(entries)
    state.loaded = true
  end
end

--- @param query string
--- @param max   integer?
--- @return table[] -- { name, description, latest_version }
function M.search(query, max)
  ensure_index()
  if query == "" then return {} end
  max = max or 50
  local q = query:lower()
  local res = {}
  for _, item in ipairs(state.flat) do
    if item.name:lower():find(q, 1, true) then
      local pk = state.by_name[item.name]
      table.insert(res, {
        name           = item.name,
        description    = item.description,
        latest_version = pk and pk.latest or "0.0.0",
      })
      if #res >= max then break end
    end
  end
  return res
end

--- @param name string
--- @return string[]|nil
function M.versions(name)
  ensure_index()
  local pk = state.by_name[name]
  if not pk then return nil end
  local vs = vim.tbl_keys(pk.versions)
  table.sort(vs, semver.compare)
  return vs
end

--- @param name string
--- @return string|nil
function M.latest(name)
  ensure_index()
  local pk = state.by_name[name]
  return pk and pk.latest or nil
end

--- @param name string
--- @param ver  string?
--- @return MooncakeEntry|nil
function M.get(name, ver)
  ensure_index()
  local pk = state.by_name[name]
  if not pk then return nil end
  ver = ver or pk.latest
  return pk.versions[ver]
end

function M.preload()
  state.loaded = false
  ensure_index()
end

return M

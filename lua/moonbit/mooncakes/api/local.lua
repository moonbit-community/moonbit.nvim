local semver     = require("moonbit.mooncakes.util.semver")
local fn         = vim.fn

---@class MooncakeEntry
---@field name        string
---@field version     string
---@field description string?
---@field license     string?
---@field checksum    string
---@field created_at  string

---@class PkgIndex
---@field latest      string
---@field versions    table<string,MooncakeEntry>
---@field description string?

local M = {}
local state = { by_name = {}, flat = {}, loaded = false }

local function build_index(mods)
  local by_name, flat = {}, {}
  for _, m in ipairs(mods) do
    local pkg = by_name[m.name]
    if not pkg then
      pkg = {
        latest      = m.version,
        description = m.description or "",
        versions    = {},
      }
      by_name[m.name] = pkg
      table.insert(flat, { name = m.name, description = pkg.description })
    elseif semver.compare(m.version, pkg.latest) > 0 then
      pkg.latest = m.version
    end
    pkg.versions[m.version] = m
  end
  return by_name, flat
end

local function load_local_entries()
  local entries = {}
  local base = fn.expand("~/.moon/registry/index/user")
  local creators = fn.glob(base .. "/*", true, true)
  for _, creator_path in ipairs(creators) do
    local files = fn.glob(creator_path .. "/*.index", true, true)
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
    state.by_name, state.flat = build_index(entries)
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

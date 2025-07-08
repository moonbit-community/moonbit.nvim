local curl       = require("plenary.curl")
local semver     = require("moonbit.mooncakes.util.semver")
local uv         = vim.uv
local fn         = vim.fn

local URL        = "https://mooncakes.io/assets/modules.json"
local CACHE_TTL  = 60 * 60
local MAX_RESULT = 50

local path_sep = package.config:sub(1, 1)

local cache_dir  = fn.stdpath("cache") .. path_sep .. "mooncakes"
local cache_file = cache_dir .. path_sep .. "modules.json"

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

local state      = { ts = 0, by_name = {}, flat = {} }

local function build_index(mods)
  local by_name, flat = {}, {}

  for _, m in ipairs(mods) do
    local pkg = by_name[m.name]
    if not pkg then
      pkg = { latest = m.version, description = m.description or "", versions = {} }
      by_name[m.name] = pkg
      table.insert(flat, { name = m.name, description = pkg.description })
    else
      if semver.compare(m.version, pkg.latest) > 0 then
        pkg.latest = m.version
      end
    end
    pkg.versions[m.version] = m
  end

  return by_name, flat
end

local function load_persistent_cache(mtime)
  local fh = io.open(cache_file, "r")
  if not fh then return false end
  local data = fh:read("*a")
  fh:close()
  local ok, decoded = pcall(vim.json.decode, data)
  if not ok or type(decoded.modules) ~= "table" then return false end
  state.by_name, state.flat = build_index(decoded.modules)
  state.ts = mtime
  return true
end

local function write_persistent_cache(body)
  fn.mkdir(cache_dir, "p")
  local fh = io.open(cache_file, "w")
  if not fh then return end
  fh:write(body)
  fh:close()
end

local function refresh(force)
  local now = os.time()
  -- 1) Memory cache
  if not force and (now - state.ts < CACHE_TTL) then
    return true
  end

  -- 2) Persistent cache
  local st = uv.fs_stat(cache_file)
  if st and not force and (now - st.mtime.sec < CACHE_TTL) then
    if load_persistent_cache(st.mtime.sec) then
      return true
    end
  end

  local resp = curl.get(URL, { timeout = 5000 })
  if resp.status == 200 then
    local ok, decoded = pcall(vim.json.decode, resp.body)
    if ok and type(decoded.modules) == "table" then
      state.by_name, state.flat = build_index(decoded.modules)
      state.ts = now
      write_persistent_cache(resp.body)
      return true
    end
  end

  if st then
    if load_persistent_cache(st.mtime.sec) then
      vim.notify("mooncakes: using stale cache due to network error", vim.log.levels.WARN)
      return true
    end
  end

  vim.notify(("mooncakes: failed to fetch registry (%s)"):format(resp.status),
    vim.log.levels.WARN)
  return false
end

-- API
local M = {}

---@param query string
---@param max   integer?
---@return table[] -- { name, description, latest_version }
function M.search(query, max)
  if query == "" then return {} end
  max = max or MAX_RESULT
  refresh()

  local res, q = {}, query:lower()
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

---Get all package versions
---@param name string
---@return string[]|nil
function M.versions(name)
  refresh()
  local pk = state.by_name[name]
  if not pk then return nil end

  local vs = vim.tbl_keys(pk.versions)
  table.sort(vs, semver.compare)
  return vs
end

---Get latest version of a package
function M.latest(name)
  refresh()
  local pk = state.by_name[name]
  return pk and pk.latest or nil
end

---Get complete MooncakeEntry
function M.get(name, ver)
  refresh()
  local pk = state.by_name[name]
  if not pk then return nil end
  ver = ver or pk.latest
  return pk.versions[ver]
end

function M.preload()
  refresh(true)
end

return M

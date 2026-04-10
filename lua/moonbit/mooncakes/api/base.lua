local semver = require("moonbit.mooncakes.util.semver")

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

---@param mods MooncakeEntry[]
---@return table<string,PkgIndex>, { name: string, description: string }[]
function M.build_index(mods)
  local by_name, flat = {}, {}
  for _, m in ipairs(mods) do
    local pkg = by_name[m.name]
    if not pkg then
      ---@type PkgIndex
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

return M

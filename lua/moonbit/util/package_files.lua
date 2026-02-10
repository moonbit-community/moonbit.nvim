local uv = vim.uv or vim.loop

local M = {
  MOON_PKG = 'moon.pkg',
  MOON_PKG_JSON = 'moon.pkg.json',
}

M.package_files = { M.MOON_PKG, M.MOON_PKG_JSON }

---@param name string
---@return boolean
function M.is_package_filename(name)
  return name == M.MOON_PKG or name == M.MOON_PKG_JSON
end

---@param dir string
---@return string|nil
---@return string|nil
function M.find_package_file(dir)
  local moon_pkg = vim.fs.joinpath(dir, M.MOON_PKG)
  if uv.fs_stat(moon_pkg) ~= nil then
    return moon_pkg, M.MOON_PKG
  end

  local moon_pkg_json = vim.fs.joinpath(dir, M.MOON_PKG_JSON)
  if uv.fs_stat(moon_pkg_json) ~= nil then
    return moon_pkg_json, M.MOON_PKG_JSON
  end

  return nil, nil
end

return M

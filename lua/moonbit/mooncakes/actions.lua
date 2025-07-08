local api    = require("moonbit.mooncakes.api")
local semver = require("moonbit.mooncakes.util.semver")
local url    = require("moonbit.mooncakes.util.openurl")
local virt   = require("moonbit.mooncakes.virtualtext")

local M      = {}

---@param bufnr number?
---@return table<string, {lnum: number, version: string}>
local function collect_deps(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local res, in_deps, depth = {}, false, 0
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for idx, line in ipairs(lines) do
    if not in_deps then
      if line:match('"deps"%s*:%s*{') then
        in_deps, depth = true, 1
      end
    else
      depth = depth
          + select(2, line:gsub("{", ""))
          - select(2, line:gsub("}", ""))
      if depth <= 0 then
        in_deps = false
      end
    end

    if in_deps then
      local name, ver = line:match('^%s*"([^"]+)"%s*:%s*"([^"]+)"')
      if name and ver then
        res[name] = { lnum = idx - 1, version = ver }
      end
    end
  end

  return res
end

---@param row number  -- 0-based
---@param old string
---@param new string
local function replace_version(row, old, new)
  local buf = vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
  local updated = line:gsub('"' .. vim.pesc(old) .. '"', '"' .. new .. '"', 1)
  vim.api.nvim_buf_set_lines(buf, row, row + 1, false, { updated })
end

---@param pkg string
---@param cur string
---@param latest string
---@param force boolean
local function upgrade(pkg, cur, latest, force)
  if not latest or semver.compare(latest, cur) <= 0 then
    vim.notify("mooncakes: already up to date", vim.log.levels.INFO)
    return
  end
  -- is a breaking change?
  local major_cur    = tonumber(cur:match("^(%d+)")) or 0
  local major_latest = tonumber(latest:match("^(%d+)")) or 0
  if not force and major_latest > major_cur then
    vim.notify(
      ("mooncakes: breaking change %s → %s (use force)"):format(cur, latest),
      vim.log.levels.WARN
    )
    return
  end

  local deps = collect_deps()
  local meta = deps[pkg]
  if meta then
    replace_version(meta.lnum, cur, latest)
    virt.refresh()
    vim.notify(
      ("mooncakes: %s upgraded to %s"):format(pkg, latest),
      vim.log.levels.INFO
    )
  end
end

function M.show_menu()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local line = vim.api.nvim_get_current_line()
  local pkg, cur = line:match('^%s*"([^"]+)"%s*:%s*"([^"]+)"')
  if not pkg then
    vim.notify("mooncakes: not on a dependency line", vim.log.levels.WARN)
    return
  end

  local latest = api.latest(pkg)
  local opts = {
    "Open documentation",
    "Update (compatible)",
    "Update (breaking)",
  }

  vim.ui.select(opts, { prompt = ("mooncakes · %s (%s)"):format(pkg, cur) },
    function(choice)
      if choice == "Open documentation" then
        url.open_url("https://mooncakes.io/docs/" .. pkg)
      elseif choice == "Update (compatible)" then
        upgrade(pkg, cur, latest, false)
      elseif choice == "Update (breaking)" then
        upgrade(pkg, cur, latest, true)
      end
    end
  )
end

function M.upgrade_all(opts)
  opts = opts or { force = false }
  local deps = collect_deps()
  local changed = 0

  for pkg, meta in pairs(deps) do
    local cur    = meta.version
    local latest = api.latest(pkg)
    if latest and semver.compare(latest, cur) > 0 then
      local major_cur    = tonumber(cur:match("^(%d+)")) or 0
      local major_latest = tonumber(latest:match("^(%d+)")) or 0
      if opts.force or major_latest == major_cur then
        replace_version(meta.lnum, cur, latest)
        changed = changed + 1
      end
    end
  end

  virt.refresh()
  vim.notify(
    ("mooncakes: upgraded %d dependencies"):format(changed),
    vim.log.levels.INFO
  )
end

function M.attach(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_create_user_command("MooncakeActions", M.show_menu, {
    nargs = 0,
    desc = "Show Mooncake actions menu",
  })
  vim.api.nvim_create_user_command("MooncakeUpgradeAll", function() M.upgrade_all { force = false } end, {
    nargs = 0,
    desc = "Mooncake upgrade all (compatible)",
  })
end

return M

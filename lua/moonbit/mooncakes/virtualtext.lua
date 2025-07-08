local api     = require("moonbit.mooncakes.api")
local semver  = require("moonbit.mooncakes.util.semver")
local M       = {}

local ns      = vim.api.nvim_create_namespace("MooncakesVirt")

local symbols = {
  up    = "󰄬",
  minor = "󰅗",
  major = "󰛨",
  error = "✗",
}

local function define(name, link)
  if vim.fn.hlexists(name) == 0 then
    vim.api.nvim_set_hl(0, name, { default = true, link = link })
  end
end

define("MooncakesUpToDate", "DiagnosticOk")
define("MooncakesMinor", "DiagnosticHint")
define("MooncakesMajor", "DiagnosticWarn")
define("MooncakesError", "DiagnosticError")

local function collect_deps(bufnr)
  local res, in_deps, depth = {}, false, 0
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for i, line in ipairs(lines) do
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
      local pkg, ver, key_start = line:match('^%s*"([^"]+)"%s*:%s*"([^"]+)"()')
      if pkg and ver then
        res[pkg] = { lnum = i - 1, version = ver }
      end
    end
  end

  return res
end

local function render_buf(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  for pkg, meta in pairs(collect_deps(bufnr)) do
    local icon, hl, text
    local latest = api.latest(pkg)

    if api.get(pkg, meta.version) == nil then
      icon = symbols.error
      hl   = "MooncakesError"
      if latest then
        text = meta.version .. " → " .. latest
      else
        text = meta.version
      end
    else
      if not latest then
        icon = symbols.error
        hl   = "MooncakesError"
        text = meta.version
      else
        local cmp = semver.compare(latest, meta.version)
        if cmp == 0 then
          icon = symbols.up
          hl   = "MooncakesUpToDate"
          text = latest
        elseif cmp > 0 then
          local major_cur    = tonumber(meta.version:match("^(%d+)")) or 0
          local major_latest = tonumber(latest:match("^(%d+)")) or 0

          if major_latest > major_cur then
            icon = symbols.major
            hl   = "MooncakesMajor"
          else
            icon = symbols.minor
            hl   = "MooncakesMinor"
          end

          text = meta.version .. " → " .. latest
        else
          icon = symbols.error
          hl   = "MooncakesError"
          text = meta.version .. " → " .. latest
        end
      end
    end

    vim.api.nvim_buf_set_extmark(bufnr, ns, meta.lnum, -1, {
      virt_text     = { { " " .. icon .. " " .. text, hl } },
      virt_text_pos = "eol",
      hl_mode       = "combine",
    })
  end
end

-- API
function M.refresh()
  render_buf(vim.api.nvim_get_current_buf())
end

function M.attach(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  render_buf(bufnr)

  local timer = vim.uv.new_timer()
  local function schedule()
    timer:stop()
    timer:start(200, 0, function()
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
          render_buf(bufnr)
        end
      end)
    end)
  end

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWritePost" }, {
    buffer   = bufnr,
    group    = vim.api.nvim_create_augroup("MooncakesVirt", { clear = false }),
    callback = schedule,
    desc     = "Refresh Moonbit crate version badges",
  })
end

return M

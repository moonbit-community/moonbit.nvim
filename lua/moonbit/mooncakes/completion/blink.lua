---@module 'blink.cmp'
---@class blink.cmp.Source
local source = {}

local api    = require("moonbit.mooncakes.api")
local types  = require("blink.cmp.types")

function source.new(opts)
  opts = opts or {}
  opts.max_items = opts.max_items or 50
  return setmetatable({ opts = opts }, { __index = source })
end

function source:enabled()
  return vim.fn.expand("%:t") == "moon.mod.json"
end

local function inside_deps(bufnr, row)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, row + 1, false)
  local in_deps, depth = false, 0

  for _, line in ipairs(lines) do
    if not in_deps and line:match('"deps"%s*:%s*{') then
      in_deps, depth = true, 1
    elseif in_deps then
      depth = depth
          + select(2, line:gsub("{", ""))
          - select(2, line:gsub("}", ""))
      if depth <= 0 then
        in_deps = false
      end
    end
  end

  return in_deps
end

function source:get_completions(ctx, callback)
  local cursor = ctx:get_cursor()
  local row = cursor[1] - 1
  -- local col = cursor[2] - 1

  if not inside_deps(ctx.bufnr, row) then
    ---@diagnostic disable-next-line: missing-return-value
    return callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
  end

  local query = ctx:get_keyword() or ""

  local items = {}
  for _, pkg in ipairs(api.search(query)) do
    table.insert(items, {
      label            = pkg.name,
      kind             = types.CompletionItemKind.Module,
      detail           = "latest: " .. pkg.latest_version,
      documentation    = pkg.description and { kind = "markdown", value = pkg.description } or nil,
      insertText       = pkg.name,
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
    })
  end

  callback({
    items                  = items,
    is_incomplete_forward  = true,
    is_incomplete_backward = true,
  })
  ---@diagnostic disable-next-line: return-type-mismatch
  return nil
end

function source:resolve(item, callback)
  callback(item)
end

return source

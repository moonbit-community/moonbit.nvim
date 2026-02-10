local api = require("moonbit.mooncakes.api")
local moon_pkg = require("moonbit.util.moon_pkg")

local source = {}

local defaults = {
  max_items = 50,
}

source.new = function()
  return setmetatable({}, { __index = source })
end

function source:is_available()
  local filename = vim.fn.expand("%:t")
  return filename == "moon.mod.json" or filename == "moon.pkg"
end

function source:get_debug_name()
  return "mooncake"
end

function source:get_keyword_pattern()
  return [[\%(\k\|/\|-\|\.\)\+]]
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

--- @param params cmp.SourceCompletionApiParams
--- @return table
function source:_validate_options(params)
  local opts = vim.tbl_deep_extend("keep", params.option or {}, defaults)
  vim.validate({
    max_items = { opts.max_items, "number" },
  })
  return opts
end

--- @param params cmp.SourceCompletionApiParams
--- @param callback fun(response: lsp.CompletionResponse|nil)
function source:complete(params, callback)
  local opts = self:_validate_options(params)
  local row = params.context.cursor.row - 1
  local filename = vim.fs.basename(vim.api.nvim_buf_get_name(params.context.bufnr))

  local in_scope = false
  if filename == "moon.mod.json" then
    in_scope = inside_deps(params.context.bufnr, row)
  elseif filename == "moon.pkg" then
    in_scope = moon_pkg.in_import_block(params.context.bufnr, row)
  end

  if not in_scope then
    callback({ items = {}, isIncomplete = false })
    return
  end

  local query = string.sub(params.context.cursor_before_line, params.offset)
  local items = {}

  for _, pkg in ipairs(api.search(query, opts.max_items)) do
    table.insert(items, {
      label            = pkg.name,
      kind             = vim.lsp.protocol.CompletionItemKind.Module,
      detail           = "latest: " .. pkg.latest_version,
      documentation    = pkg.description and { kind = "markdown", value = pkg.description } or nil,
      insertText       = pkg.name,
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
    })
  end

  callback({
    items = items,
    isIncomplete = true,
  })
end

--- @param completion_item lsp.CompletionItem
--- @param callback fun(completion_item: lsp.CompletionItem|nil)
function source:resolve(completion_item, callback)
  callback(completion_item)
end

return source

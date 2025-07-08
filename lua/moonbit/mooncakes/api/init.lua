local http      = require("moonbit.mooncakes.api.http")
local l         = require("moonbit.mooncakes.api.local")

local use_local = true

local M         = {}
setmetatable(M, {
  __index = function(_, key)
    if use_local then
      return l[key]
    else
      return http[key]
    end
  end,
})

--- @param opts table  { use_local = boolean }
function M.setup(opts)
  opts = opts or {}
  if opts.use_local ~= nil then
    use_local = opts.use_local
  end
end

return M

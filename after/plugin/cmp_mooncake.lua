local ok, cmp = pcall(require, "cmp")
if not ok then
  return
end

if type(cmp.get_registered_sources) == "function" then
  for _, src in ipairs(cmp.get_registered_sources()) do
    if src.name == "mooncake" then
      return
    end
  end
end

if type(cmp.register_source) ~= "function" then
  return
end

local source = require("moonbit.mooncakes.completion.cmp").new()
local ok_register = pcall(cmp.register_source, "mooncake", source)
if not ok_register then
  return
end

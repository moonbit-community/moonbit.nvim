local ok, cmp = pcall(require, "cmp")
if not ok then
  return
end

for _, src in ipairs(cmp.get_registered_sources()) do
  if src.name == "mooncake" then
    return
  end
end

cmp.register_source("mooncake", require("moonbit.mooncakes.completion.cmp").new())

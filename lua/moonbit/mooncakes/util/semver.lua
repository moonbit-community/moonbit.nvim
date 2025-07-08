local M = {}

local function parse(v)
  if type(v) ~= "string" then
    return { major = 0, minor = 0, patch = 0, pre = nil }
  end

  local s = v:match("^[vV]?(.*)") or v

  s = s:match("([^+]+)") or s

  local core, pre = s:match("^([0-9]+%.[0-9]+%.[0-9]+)%-?(.*)$")
  if core then
    local major, minor, patch = core:match("(%d+)%.(%d+)%.(%d+)")
    major = tonumber(major) or 0
    minor = tonumber(minor) or 0
    patch = tonumber(patch) or 0

    if pre == "" then pre = nil end

    local pre_parts = nil
    if pre then
      pre_parts = {}
      for part in pre:gmatch("[^%.]+") do
        local n = tonumber(part)
        pre_parts[#pre_parts+1] = (n and n or part)
      end
    end

    return { major = major, minor = minor, patch = patch, pre = pre_parts }
  end

  local maj, min, pat = s:match("(%d+)") or "0", s:match("%d+%.(%d+)") or "0", s:match("%d+%.%d+%.(%d+)") or "0"
  return {
    major = tonumber(maj) or 0,
    minor = tonumber(min) or 0,
    patch = tonumber(pat) or 0,
    pre   = nil,
  }
end

local function cmp_prerelease(a, b)
  if not a and not b then return 0 end
  if not a          then return  1 end
  if not b          then return -1 end

  local n = math.max(#a, #b)
  for i = 1, n do
    local ai, bi = a[i], b[i]
    if ai == bi then
    else
      if type(ai) == "number" and type(bi) == "number" then
        return ai > bi and 1 or -1
      end
      if type(ai) == "number" and type(bi) == "string" then
        return -1
      end
      if type(ai) == "string" and type(bi) == "number" then
        return 1
      end
      return (ai > bi) and 1 or -1
    end
  end
  return 0
end

--- @param a string  
--- @param b string  
--- @return number 1 if a>b, 0 if a==b, -1 if a<b
function M.compare(a, b)
  local A = parse(a)
  local B = parse(b)

  if A.major ~= B.major then
    return (A.major > B.major) and 1 or -1
  end
  if A.minor ~= B.minor then
    return (A.minor > B.minor) and 1 or -1
  end
  if A.patch ~= B.patch then
    return (A.patch > B.patch) and 1 or -1
  end

  return cmp_prerelease(A.pre, B.pre)
end

return M

-- mocks for LÖVE functions
local Quadmt = {
  __eq = function(a,b)
    if #a ~= #b then return false end
    for i,v in ipairs(a) do
      if b[i] ~= v then return false end
    end
    return true
  end,
  __tostring = function(self)
    local buffer = {}
    for i,v in ipairs(self) do
      buffer[i] = tostring(v)
    end
    return "quad: {" .. table.concat(buffer, ",") .. "}"
  end,
  getViewport = function(self)
    return unpack(self)
  end
}

Quadmt.__index = Quadmt

love = {
  graphics = {
    newQuad = function(...)
      return setmetatable({...}, Quadmt)
    end,
    draw = function()
    end,
    getLastDrawq = function()
    end
  }
}

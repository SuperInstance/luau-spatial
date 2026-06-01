--[[
    Vec2 - 2D vector math for spatial indexing
]]

local Vec2 = {}
Vec2.__index = Vec2

export type Vec2 = typeof(setmetatable({ x = 0, y = 0 }, Vec2))

function Vec2.new(x: number, y: number): Vec2
    return setmetatable({ x = x, y = y }, Vec2)
end

function Vec2.zero(): Vec2
    return Vec2.new(0, 0)
end

function Vec2:length(): number
    return math.sqrt(self.x * self.x + self.y * self.y)
end

function Vec2:lengthSquared(): number
    return self.x * self.x + self.y * self.y
end

function Vec2:distanceTo(other: Vec2): number
    local dx = self.x - other.x
    local dy = self.y - other.y
    return math.sqrt(dx * dx + dy * dy)
end

function Vec2:distanceSquaredTo(other: Vec2): number
    local dx = self.x - other.x
    local dy = self.y - other.y
    return dx * dx + dy * dy
end

function Vec2:normalize(): Vec2
    local len = self:length()
    if len == 0 then
        return Vec2.zero()
    end
    return Vec2.new(self.x / len, self.y / len)
end

function Vec2:dot(other: Vec2): number
    return self.x * other.x + self.y * other.y
end

function Vec2:add(other: Vec2): Vec2
    return Vec2.new(self.x + other.x, self.y + other.y)
end

function Vec2:sub(other: Vec2): Vec2
    return Vec2.new(self.x - other.x, self.y - other.y)
end

function Vec2:scale(s: number): Vec2
    return Vec2.new(self.x * s, self.y * s)
end

function Vec2:clone(): Vec2
    return Vec2.new(self.x, self.y)
end

function Vec2.__eq(a: Vec2, b: Vec2): boolean
    return a.x == b.x and a.y == b.y
end

function Vec2.__tostring(self: Vec2): string
    return string.format("Vec2(%.4f, %.4f)", self.x, self.y)
end

return Vec2

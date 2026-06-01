--[[
    Vec3 - 3D vector math for spatial indexing
]]

local Vec3 = {}
Vec3.__index = Vec3

export type Vec3 = typeof(setmetatable({ x = 0, y = 0, z = 0 }, Vec3))

function Vec3.new(x: number, y: number, z: number): Vec3
    return setmetatable({ x = x, y = y, z = z }, Vec3)
end

function Vec3.zero(): Vec3
    return Vec3.new(0, 0, 0)
end

function Vec3:length(): number
    return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

function Vec3:lengthSquared(): number
    return self.x * self.x + self.y * self.y + self.z * self.z
end

function Vec3:distanceTo(other: Vec3): number
    local dx = self.x - other.x
    local dy = self.y - other.y
    local dz = self.z - other.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function Vec3:distanceSquaredTo(other: Vec3): number
    local dx = self.x - other.x
    local dy = self.y - other.y
    local dz = self.z - other.z
    return dx * dx + dy * dy + dz * dz
end

function Vec3:normalize(): Vec3
    local len = self:length()
    if len == 0 then
        return Vec3.zero()
    end
    return Vec3.new(self.x / len, self.y / len, self.z / len)
end

function Vec3:dot(other: Vec3): number
    return self.x * other.x + self.y * other.y + self.z * other.z
end

function Vec3:cross(other: Vec3): Vec3
    return Vec3.new(
        self.y * other.z - self.z * other.y,
        self.z * other.x - self.x * other.z,
        self.x * other.y - self.y * other.x
    )
end

function Vec3:add(other: Vec3): Vec3
    return Vec3.new(self.x + other.x, self.y + other.y, self.z + other.z)
end

function Vec3:sub(other: Vec3): Vec3
    return Vec3.new(self.x - other.x, self.y - other.y, self.z - other.z)
end

function Vec3:scale(s: number): Vec3
    return Vec3.new(self.x * s, self.y * s, self.z * s)
end

function Vec3:clone(): Vec3
    return Vec3.new(self.x, self.y, self.z)
end

function Vec3.__eq(a: Vec3, b: Vec3): boolean
    return a.x == b.x and a.y == b.y and a.z == b.z
end

function Vec3.__tostring(self: Vec3): string
    return string.format("Vec3(%.4f, %.4f, %.4f)", self.x, self.y, self.z)
end

return Vec3

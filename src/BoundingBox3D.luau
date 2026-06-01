--[[
    BoundingBox3D - Axis-aligned bounding box for 3D spatial queries
]]

local Vec3 = require(script.Parent.Vec3)

local BoundingBox3D = {}
BoundingBox3D.__index = BoundingBox3D

export type BoundingBox3D = typeof(setmetatable({
    min = Vec3.zero(),
    max = Vec3.zero(),
}, BoundingBox3D))

function BoundingBox3D.new(minPos: Vec3.Vec3, maxPos: Vec3.Vec3): BoundingBox3D
    return setmetatable({
        min = minPos,
        max = maxPos,
    }, BoundingBox3D)
end

function BoundingBox3D.fromCenter(center: Vec3.Vec3, halfW: number, halfH: number?, halfD: number?): BoundingBox3D
    local hw = halfW
    local hh = halfH or halfW
    local hd = halfD or halfW
    return BoundingBox3D.new(
        Vec3.new(center.x - hw, center.y - hh, center.z - hd),
        Vec3.new(center.x + hw, center.y + hh, center.z + hd)
    )
end

function BoundingBox3D:contains(point: Vec3.Vec3): boolean
    return point.x >= self.min.x
        and point.x <= self.max.x
        and point.y >= self.min.y
        and point.y <= self.max.y
        and point.z >= self.min.z
        and point.z <= self.max.z
end

function BoundingBox3D:intersects(other: BoundingBox3D): boolean
    return self.min.x <= other.max.x
        and self.max.x >= other.min.x
        and self.min.y <= other.max.y
        and self.max.y >= other.min.y
        and self.min.z <= other.max.z
        and self.max.z >= other.min.z
end

function BoundingBox3D:center(): Vec3.Vec3
    return Vec3.new(
        (self.min.x + self.max.x) / 2,
        (self.min.y + self.max.y) / 2,
        (self.min.z + self.max.z) / 2
    )
end

function BoundingBox3D:width(): number
    return self.max.x - self.min.x
end

function BoundingBox3D:height(): number
    return self.max.y - self.min.y
end

function BoundingBox3D:depth(): number
    return self.max.z - self.min.z
end

function BoundingBox3D:containsSphere(center: Vec3.Vec3, radius: number): boolean
    local closestX = math.max(self.min.x, math.min(center.x, self.max.x))
    local closestY = math.max(self.min.y, math.min(center.y, self.max.y))
    local closestZ = math.max(self.min.z, math.min(center.z, self.max.z))
    local dx = center.x - closestX
    local dy = center.y - closestY
    local dz = center.z - closestZ
    return (dx * dx + dy * dy + dz * dz) <= radius * radius
end

function BoundingBox3D:clone(): BoundingBox3D
    return BoundingBox3D.new(self.min:clone(), self.max:clone())
end

function BoundingBox3D.__tostring(self: BoundingBox3D): string
    return string.format("BoundingBox3D(%s, %s)", tostring(self.min), tostring(self.max))
end

return BoundingBox3D

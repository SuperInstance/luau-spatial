--[[
    BoundingBox - Axis-aligned bounding box for spatial queries
]]

local Vec2 = require(script.Parent.Vec2)

local BoundingBox = {}
BoundingBox.__index = BoundingBox

export type BoundingBox = typeof(setmetatable({
    min = Vec2.zero(),
    max = Vec2.zero(),
}, BoundingBox))

function BoundingBox.new(minPos: Vec2.Vec2, maxPos: Vec2.Vec2): BoundingBox
    return setmetatable({
        min = minPos,
        max = maxPos,
    }, BoundingBox)
end

function BoundingBox.fromCenter(center: Vec2.Vec2, halfWidth: number, halfHeight: number?): BoundingBox
    local hw = halfWidth
    local hh = halfHeight or halfWidth
    return BoundingBox.new(
        Vec2.new(center.x - hw, center.y - hh),
        Vec2.new(center.x + hw, center.y + hh)
    )
end

function BoundingBox:contains(point: Vec2.Vec2): boolean
    return point.x >= self.min.x
        and point.x <= self.max.x
        and point.y >= self.min.y
        and point.y <= self.max.y
end

function BoundingBox:intersects(other: BoundingBox): boolean
    return self.min.x <= other.max.x
        and self.max.x >= other.min.x
        and self.min.y <= other.max.y
        and self.max.y >= other.min.y
end

function BoundingBox:center(): Vec2.Vec2
    return Vec2.new(
        (self.min.x + self.max.x) / 2,
        (self.min.y + self.max.y) / 2
    )
end

function BoundingBox:width(): number
    return self.max.x - self.min.x
end

function BoundingBox:height(): number
    return self.max.y - self.min.y
end

function BoundingBox:containsCircle(center: Vec2.Vec2, radius: number): boolean
    local closestX = math.max(self.min.x, math.min(center.x, self.max.x))
    local closestY = math.max(self.min.y, math.min(center.y, self.max.y))
    local dx = center.x - closestX
    local dy = center.y - closestY
    return (dx * dx + dy * dy) <= radius * radius
end

function BoundingBox:clone(): BoundingBox
    return BoundingBox.new(self.min:clone(), self.max:clone())
end

function BoundingBox.__tostring(self: BoundingBox): string
    return string.format("BoundingBox(%s, %s)", tostring(self.min), tostring(self.max))
end

return BoundingBox

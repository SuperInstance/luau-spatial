--[[
    OcTree - Hierarchical spatial index for 3D points
    The 3D equivalent of QuadTree. Efficient for non-uniform
    distributions with O(log n) queries.
]]

local Vec3 = require(script.Parent.Vec3)
local BoundingBox3D = require(script.Parent.BoundingBox3D)

export type OtEntry = { pos: Vec3.Vec3, data: any }

local OcTree = {}
OcTree.__index = OcTree

export type OcTree = typeof(setmetatable({}, OcTree)) & {
    bounds: BoundingBox3D.BoundingBox3D,
    capacity: number,
    entries: { OtEntry },
    divided: boolean,
    children: { OcTree? },
}

local DEFAULT_CAPACITY = 8

-- Octant indices: ordered as binary xyz (0=---, 1=++-, 2=-+-, 3=+++, 4=--+, 5=+-+, 6=-++, 7=+++)
-- More explicitly: bit0=x, bit1=y, bit2=z
local function getOctantIndex(mid: Vec3.Vec3, point: Vec3.Vec3): number
    local idx = 0
    if point.x >= mid.x then idx = bit32.bor(idx, 1) end
    if point.y >= mid.y then idx = bit32.bor(idx, 2) end
    if point.z >= mid.z then idx = bit32.bor(idx, 4) end
    return idx
end

function OcTree.new(bounds: BoundingBox3D.BoundingBox3D, capacity: number?): OcTree
    local cap = capacity or DEFAULT_CAPACITY
    return setmetatable({
        bounds = bounds,
        capacity = cap,
        entries = {},
        divided = false,
        children = {},
    }, OcTree)
end

function OcTree:subdivide()
    local min = self.bounds.min
    local max = self.bounds.max
    local midX = (min.x + max.x) / 2
    local midY = (min.y + max.y) / 2
    local midZ = (min.z + max.z) / 2
    local mid = Vec3.new(midX, midY, midZ)

    -- Create 8 octant bounds
    -- Octant ordering: bit0=x, bit1=y, bit2=z
    local octantBounds = {
        -- 0: (-,-,-) = min..mid
        BoundingBox3D.new(Vec3.new(min.x, min.y, min.z), Vec3.new(midX, midY, midZ)),
        -- 1: (+,-,-) = midX..max x, min..mid y, min..mid z
        BoundingBox3D.new(Vec3.new(midX, min.y, min.z), Vec3.new(max.x, midY, midZ)),
        -- 2: (-,+,-)
        BoundingBox3D.new(Vec3.new(min.x, midY, min.z), Vec3.new(midX, max.y, midZ)),
        -- 3: (+,+,-)
        BoundingBox3D.new(Vec3.new(midX, midY, min.z), Vec3.new(max.x, max.y, midZ)),
        -- 4: (-,-,+)
        BoundingBox3D.new(Vec3.new(min.x, min.y, midZ), Vec3.new(midX, midY, max.z)),
        -- 5: (+,-,+)
        BoundingBox3D.new(Vec3.new(midX, min.y, midZ), Vec3.new(max.x, midY, max.z)),
        -- 6: (-,+,+)
        BoundingBox3D.new(Vec3.new(min.x, midY, midZ), Vec3.new(midX, max.y, max.z)),
        -- 7: (+,+,+)
        BoundingBox3D.new(Vec3.new(midX, midY, midZ), Vec3.new(max.x, max.y, max.z)),
    }

    for i = 1, 8 do
        self.children[i] = OcTree.new(octantBounds[i], self.capacity)
    end
    self.divided = true
end

function OcTree:insert(pos: Vec3.Vec3, data: any): boolean
    if not self.bounds:contains(pos) then
        return false
    end

    if #self.entries < self.capacity and not self.divided then
        table.insert(self.entries, { pos = pos, data = data })
        return true
    end

    if not self.divided then
        self:subdivide()
        -- Re-insert existing entries into children
        local oldEntries = self.entries
        self.entries = {}
        for _, entry in oldEntries do
            self:_insertIntoChild(entry.pos, entry.data)
        end
    end

    return self:_insertIntoChild(pos, data)
end

function OcTree:_insertIntoChild(pos: Vec3.Vec3, data: any): boolean
    for i = 1, 8 do
        local child = self.children[i]
        if child and child:insert(pos, data) then
            return true
        end
    end
    -- Fallback: store locally if no child accepted (boundary edge case)
    table.insert(self.entries, { pos = pos, data = data })
    return true
end

function OcTree:queryBox(bounds: BoundingBox3D.BoundingBox3D, results: { OtEntry }?): { OtEntry }
    local out = results or {}

    if not self.bounds:intersects(bounds) then
        return out
    end

    for _, entry in self.entries do
        if bounds:contains(entry.pos) then
            table.insert(out, entry)
        end
    end

    if self.divided then
        for i = 1, 8 do
            local child = self.children[i]
            if child then
                child:queryBox(bounds, out)
            end
        end
    end

    return out
end

function OcTree:queryRadius(center: Vec3.Vec3, radius: number): { OtEntry }
    local searchBounds = BoundingBox3D.fromCenter(center, radius)
    local candidates = self:queryBox(searchBounds)
    local r2 = radius * radius
    local results = {}

    for _, entry in candidates do
        local dx = entry.pos.x - center.x
        local dy = entry.pos.y - center.y
        local dz = entry.pos.z - center.z
        if dx * dx + dy * dy + dz * dz <= r2 then
            table.insert(results, entry)
        end
    end

    return results
end

function OcTree:remove(pos: Vec3.Vec3): boolean
    if not self.bounds:contains(pos) then
        return false
    end

    for i, entry in self.entries do
        if entry.pos == pos then
            table.remove(self.entries, i)
            return true
        end
    end

    if self.divided then
        for i = 1, 8 do
            local child = self.children[i]
            if child and child:remove(pos) then
                return true
            end
        end
    end

    return false
end

function OcTree:count(): number
    local n = #self.entries
    if self.divided then
        for i = 1, 8 do
            local child = self.children[i]
            if child then
                n += child:count()
            end
        end
    end
    return n
end

function OcTree:clear()
    self.entries = {}
    self.divided = false
    self.children = {}
end

return OcTree

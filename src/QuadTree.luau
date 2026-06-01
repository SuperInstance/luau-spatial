--[[
    QuadTree - Hierarchical spatial index for 2D points
    Efficient for non-uniform distributions with O(log n) queries.
]]

local Vec2 = require(script.Parent.Vec2)
local BoundingBox = require(script.Parent.BoundingBox)

export type QtEntry = { pos: Vec2.Vec2, data: any }

local QuadTree = {}
QuadTree.__index = QuadTree

export type QuadTree = typeof(setmetatable({}, QuadTree)) & {
    bounds: BoundingBox.BoundingBox,
    capacity: number,
    entries: { QtEntry },
    divided: boolean,
    northwest: QuadTree?,
    northeast: QuadTree?,
    southwest: QuadTree?,
    southeast: QuadTree?,
}

local DEFAULT_CAPACITY = 4

function QuadTree.new(bounds: BoundingBox.BoundingBox, capacity: number?): QuadTree
    local cap = capacity or DEFAULT_CAPACITY
    return setmetatable({
        bounds = bounds,
        capacity = cap,
        entries = {},
        divided = false,
        northwest = nil,
        northeast = nil,
        southwest = nil,
        southeast = nil,
    }, QuadTree)
end

function QuadTree:subdivide()
    local min = self.bounds.min
    local max = self.bounds.max
    local midX = (min.x + max.x) / 2
    local midY = (min.y + max.y) / 2

    local nw = BoundingBox.new(Vec2.new(min.x, midY), Vec2.new(midX, max.y))
    local ne = BoundingBox.new(Vec2.new(midX, midY), Vec2.new(max.x, max.y))
    local sw = BoundingBox.new(Vec2.new(min.x, min.y), Vec2.new(midX, midY))
    local se = BoundingBox.new(Vec2.new(midX, min.y), Vec2.new(max.x, midY))

    self.northwest = QuadTree.new(nw, self.capacity)
    self.northeast = QuadTree.new(ne, self.capacity)
    self.southwest = QuadTree.new(sw, self.capacity)
    self.southeast = QuadTree.new(se, self.capacity)
    self.divided = true
end

function QuadTree:insert(pos: Vec2.Vec2, data: any): boolean
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

function QuadTree:_insertIntoChild(pos: Vec2.Vec2, data: any): boolean
    if self.northwest and self.northwest:insert(pos, data) then return true end
    if self.northeast and self.northeast:insert(pos, data) then return true end
    if self.southwest and self.southwest:insert(pos, data) then return true end
    if self.southeast and self.southeast:insert(pos, data) then return true end
    -- Fallback: store locally if no child accepted (boundary edge case)
    table.insert(self.entries, { pos = pos, data = data })
    return true
end

function QuadTree:queryBox(bounds: BoundingBox.BoundingBox, results: { QtEntry }?): { QtEntry }
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
        self.northwest:queryBox(bounds, out)
        self.northeast:queryBox(bounds, out)
        self.southwest:queryBox(bounds, out)
        self.southeast:queryBox(bounds, out)
    end

    return out
end

function QuadTree:queryRadius(center: Vec2.Vec2, radius: number): { QtEntry }
    local searchBounds = BoundingBox.fromCenter(center, radius)
    local candidates = self:queryBox(searchBounds)
    local r2 = radius * radius
    local results = {}

    for _, entry in candidates do
        local dx = entry.pos.x - center.x
        local dy = entry.pos.y - center.y
        if dx * dx + dy * dy <= r2 then
            table.insert(results, entry)
        end
    end

    return results
end

function QuadTree:remove(pos: Vec2.Vec2): boolean
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
        if self.northwest and self.northwest:remove(pos) then return true end
        if self.northeast and self.northeast:remove(pos) then return true end
        if self.southwest and self.southwest:remove(pos) then return true end
        if self.southeast and self.southeast:remove(pos) then return true end
    end

    return false
end

function QuadTree:count(): number
    local n = #self.entries
    if self.divided then
        n += self.northwest:count()
        n += self.northeast:count()
        n += self.southwest:count()
        n += self.southeast:count()
    end
    return n
end

function QuadTree:clear()
    self.entries = {}
    self.divided = false
    self.northwest = nil
    self.northeast = nil
    self.southwest = nil
    self.southeast = nil
end

return QuadTree

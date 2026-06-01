--[[
    SpatialHash - Grid-based spatial hash for variable-sized entities
    Each entity has a position and radius. Supports broad-phase collision detection.
]]

local Vec2 = require(script.Parent.Vec2)

export type SpatialEntry = { pos: Vec2.Vec2, radius: number, data: any }

local SpatialHash = {}
SpatialHash.__index = SpatialHash

export type SpatialHash = typeof(setmetatable({}, SpatialHash)) & {
    cellSize: number,
    invCellSize: number,
    cells: { [string]: { SpatialEntry } },
    entries: { [any]: SpatialEntry },
}

function SpatialHash.new(cellSize: number): SpatialHash
    assert(cellSize > 0, "cellSize must be positive")
    return setmetatable({
        cellSize = cellSize,
        invCellSize = 1 / cellSize,
        cells = {},
        entries = {},
    }, SpatialHash)
end

function SpatialHash._key(cx: number, cy: number): string
    return string.format("%d,%d", cx, cy)
end

function SpatialHash:_coveredCells(pos: Vec2.Vec2, radius: number): { { number, number } }
    local minCX = math.floor((pos.x - radius) * self.invCellSize)
    local maxCX = math.floor((pos.x + radius) * self.invCellSize)
    local minCY = math.floor((pos.y - radius) * self.invCellSize)
    local maxCY = math.floor((pos.y + radius) * self.invCellSize)

    local cells = {}
    for cx = minCX, maxCX do
        for cy = minCY, maxCY do
            table.insert(cells, { cx, cy })
        end
    end
    return cells
end

function SpatialHash:insert(pos: Vec2.Vec2, radius: number, data: any)
    local entry: SpatialEntry = { pos = pos:clone(), radius = radius, data = data }
    local covered = self:_coveredCells(pos, radius)

    for _, coord in covered do
        local key = SpatialHash._key(coord[1], coord[2])
        if not self.cells[key] then
            self.cells[key] = {}
        end
        table.insert(self.cells[key], entry)
    end

    self.entries[data] = entry
end

function SpatialHash:remove(pos: Vec2.Vec2, radius: number)
    local covered = self:_coveredCells(pos, radius)

    for _, coord in covered do
        local key = SpatialHash._key(coord[1], coord[2])
        local cell = self.cells[key]
        if cell then
            for i = #cell, 1, -1 do
                local entry = cell[i]
                if entry.pos.x == pos.x and entry.pos.y == pos.y and entry.radius == radius then
                    self.entries[entry.data] = nil
                    table.remove(cell, i)
                end
            end
            if #cell == 0 then
                self.cells[key] = nil
            end
        end
    end
end

function SpatialHash:queryRadius(pos: Vec2.Vec2, radius: number): { SpatialEntry }
    local results = {}
    local seen = {}
    local r2 = radius * radius

    local minCX = math.floor((pos.x - radius) * self.invCellSize)
    local maxCX = math.floor((pos.x + radius) * self.invCellSize)
    local minCY = math.floor((pos.y - radius) * self.invCellSize)
    local maxCY = math.floor((pos.y + radius) * self.invCellSize)

    for cx = minCX, maxCX do
        for cy = minCY, maxCY do
            local key = SpatialHash._key(cx, cy)
            local cell = self.cells[key]
            if cell then
                for _, entry in cell do
                    if not seen[entry] then
                        local dx = entry.pos.x - pos.x
                        local dy = entry.pos.y - pos.y
                        local combinedR = radius + entry.radius
                        if dx * dx + dy * dy <= combinedR * combinedR then
                            seen[entry] = true
                            table.insert(results, entry)
                        end
                    end
                end
            end
        end
    end

    return results
end

function SpatialHash:queryPotentialCollisions(): {{ a: any, b: any }}
    local seen = {}
    local pairs = {}

    for _, cell in self.cells do
        for i = 1, #cell do
            for j = i + 1, #cell do
                local a = cell[i]
                local b = cell[j]
                -- Use a stable key to avoid duplicate pairs
                local pairKey
                if tostring(a.data) < tostring(b.data) then
                    pairKey = tostring(a.data) .. "|" .. tostring(b.data)
                else
                    pairKey = tostring(b.data) .. "|" .. tostring(a.data)
                end

                if not seen[pairKey] then
                    seen[pairKey] = true
                    local dx = a.pos.x - b.pos.x
                    local dy = a.pos.y - b.pos.y
                    local combinedR = a.radius + b.radius
                    if dx * dx + dy * dy <= combinedR * combinedR then
                        table.insert(pairs, { a = a.data, b = b.data })
                    end
                end
            end
        end
    end

    return pairs
end

function SpatialHash:clear()
    self.cells = {}
    self.entries = {}
end

function SpatialHash:count(): number
    local n = 0
    for _ in self.entries do
        n += 1
    end
    return n
end

return SpatialHash

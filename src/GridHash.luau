--[[
    GridHash - Uniform grid spatial hash
    O(1) insertion, efficient for uniformly distributed entities.
]]

local Vec2 = require(script.Parent.Vec2)

export type GridEntry = { pos: Vec2.Vec2, data: any }

local GridHash = {}
GridHash.__index = GridHash

export type GridHash = typeof(setmetatable({}, GridHash)) & {
    cellSize: number,
    cells: { [string]: { GridEntry } },
    invCellSize: number,
}

function GridHash.new(cellSize: number): GridHash
    assert(cellSize > 0, "cellSize must be positive")
    return setmetatable({
        cellSize = cellSize,
        invCellSize = 1 / cellSize,
        cells = {},
    }, GridHash)
end

function GridHash._key(cx: number, cy: number): string
    return string.format("%d,%d", cx, cy)
end

function GridHash:_cellKey(pos: Vec2.Vec2): string
    local cx = math.floor(pos.x * self.invCellSize)
    local cy = math.floor(pos.y * self.invCellSize)
    return GridHash._key(cx, cy)
end

function GridHash:_cellCoords(pos: Vec2.Vec2): (number, number)
    return math.floor(pos.x * self.invCellSize), math.floor(pos.y * self.invCellSize)
end

function GridHash:insert(pos: Vec2.Vec2, data: any)
    local key = self:_cellKey(pos)
    if not self.cells[key] then
        self.cells[key] = {}
    end
    table.insert(self.cells[key], { pos = pos:clone(), data = data })
end

function GridHash:remove(pos: Vec2.Vec2): boolean
    local key = self:_cellKey(pos)
    local cell = self.cells[key]
    if not cell then
        return false
    end
    for i, entry in cell do
        if entry.pos == pos then
            table.remove(cell, i)
            if #cell == 0 then
                self.cells[key] = nil
            end
            return true
        end
    end
    return false
end

function GridHash:queryCell(pos: Vec2.Vec2): { GridEntry }
    local key = self:_cellKey(pos)
    return self.cells[key] or {}
end

function GridHash:queryNeighbors(pos: Vec2.Vec2): { GridEntry }
    local cx, cy = self:_cellCoords(pos)
    local results = {}
    for dx = -1, 1 do
        for dy = -1, 1 do
            local key = GridHash._key(cx + dx, cy + dy)
            local cell = self.cells[key]
            if cell then
                for _, entry in cell do
                    table.insert(results, entry)
                end
            end
        end
    end
    return results
end

function GridHash:queryRadius(pos: Vec2.Vec2, radius: number): { GridEntry }
    local cx, cy = self:_cellCoords(pos)
    local results = {}
    local r2 = radius * radius

    local span = math.ceil(radius * self.invCellSize) + 1

    for dx = -span, span do
        for dy = -span, span do
            local key = GridHash._key(cx + dx, cy + dy)
            local cell = self.cells[key]
            if cell then
                for _, entry in cell do
                    local ex = entry.pos.x - pos.x
                    local ey = entry.pos.y - pos.y
                    if ex * ex + ey * ey <= r2 then
                        table.insert(results, entry)
                    end
                end
            end
        end
    end

    return results
end

function GridHash:clear()
    self.cells = {}
end

function GridHash:count(): number
    local n = 0
    for _, cell in self.cells do
        n += #cell
    end
    return n
end

return GridHash

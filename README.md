# luau-spatial

> Spatial indexing for Roblox games — QuadTree, GridHash, and SpatialHash.

## What This Does

Find what's near what, fast. Essential for collision detection, neighbor AI, proximity triggers, and rendering culling in Roblox games.

Three data structures, one goal: efficient spatial queries on ANY data — not just BaseParts.

## Install

### Option 1: Wally (recommended)

Add to your `wally.toml`:

```toml
[dependencies]
Spatial = "superinstance/luau-spatial@0.1.0"
```

Then run `wally install`.

### Option 2: Rojo

Clone this repo and use the included `default.project.json` with Rojo:

```bash
rojo serve
```

### Option 3: Manual

Copy files from `src/` into your Roblox project as ModuleScripts. Make sure the parent-child hierarchy matches the `require` paths (Vec2, BoundingBox, QuadTree, GridHash, SpatialHash all in the same folder).

## Quick Start

### QuadTree — Best for non-uniform distributions

```luau
local QuadTree = require(path.to.QuadTree)
local BoundingBox = require(path.to.BoundingBox)
local Vec2 = require(path.to.Vec2)

-- Create a tree covering a 1000×1000 world
local tree = QuadTree.new(BoundingBox.new(Vec2.new(0, 0), Vec2.new(1000, 1000)))

-- Insert NPCs, items, etc.
tree:insert(Vec2.new(50, 50), npc1)
tree:insert(Vec2.new(200, 150), npc2)

-- Find everything within 100 studs of the player
local nearby = tree:queryRadius(playerPos, 100)
for _, entry in nearby do
    print(entry.data) -- your NPC/item data
end

-- Remove something
tree:insert(pos, "item")
tree:remove(pos)
```

### GridHash — Best for uniform distributions

```luau
local GridHash = require(path.to.GridHash)

-- cellSize should match your typical query range
local grid = GridHash.new(64)

-- Insert entities
grid:insert(Vec2.new(100, 200), projectileA)
grid:insert(Vec2.new(105, 195), projectileB)

-- Get all entities in same cell + 8 neighbors
local neighbors = grid:queryNeighbors(Vec2.new(100, 200))

-- Radius query with actual distance check
local nearby = grid:queryRadius(Vec2.new(100, 200), 10)
```

### SpatialHash — Best for variable-sized entities & broad-phase collision

```luau
local SpatialHash = require(path.to.SpatialHash)

local hash = SpatialHash.new(100)

-- Insert entities with position AND size
hash:insert(Vec2.new(50, 50), 10, enemyA)
hash:insert(Vec2.new(55, 55), 15, enemyB)
hash:insert(Vec2.new(500, 500), 5, enemyC)

-- Find potential collisions
local pairs = hash:queryPotentialCollisions()
for _, pair in pairs do
    print(pair.a, "might collide with", pair.b)
end

-- Radius query that respects entity sizes
local nearby = hash:queryRadius(Vec2.new(50, 50), 20)
```

## API Reference

### Vec2

| Method | Returns | Description |
|--------|---------|-------------|
| `Vec2.new(x, y)` | `Vec2` | Create a vector |
| `Vec2.zero()` | `Vec2` | Zero vector |
| `v:length()` | `number` | Magnitude |
| `v:lengthSquared()` | `number` | Squared magnitude (no sqrt) |
| `v:distanceTo(other)` | `number` | Distance to another Vec2 |
| `v:distanceSquaredTo(other)` | `number` | Squared distance |
| `v:normalize()` | `Vec2` | Unit vector |
| `v:dot(other)` | `number` | Dot product |
| `v:add(other)` | `Vec2` | Vector addition |
| `v:sub(other)` | `Vec2` | Vector subtraction |
| `v:scale(s)` | `Vec2` | Scalar multiplication |
| `v:clone()` | `Vec2` | Copy |

### BoundingBox

| Method | Returns | Description |
|--------|---------|-------------|
| `BoundingBox.new(min, max)` | `BoundingBox` | Create from corners |
| `BoundingBox.fromCenter(center, halfW, halfH?)` | `BoundingBox` | Create from center |
| `bb:contains(point)` | `boolean` | Point containment |
| `bb:intersects(other)` | `boolean` | Box intersection |
| `bb:containsCircle(center, radius)` | `boolean` | Circle-box overlap |
| `bb:center()` | `Vec2` | Center point |
| `bb:width()` | `number` | Width |
| `bb:height()` | `number` | Height |

### QuadTree

| Method | Returns | Description |
|--------|---------|-------------|
| `QuadTree.new(bounds, capacity?)` | `QuadTree` | Create tree (default capacity: 4) |
| `qt:insert(pos, data)` | `boolean` | Insert point (false if out of bounds) |
| `qt:queryRadius(center, radius)` | `{Entry}` | Find entries within radius |
| `qt:queryBox(bounds)` | `{Entry}` | Find entries within bounding box |
| `qt:remove(pos)` | `boolean` | Remove by exact position |
| `qt:count()` | `number` | Total entries |
| `qt:clear()` | — | Remove all entries |

### GridHash

| Method | Returns | Description |
|--------|---------|-------------|
| `GridHash.new(cellSize)` | `GridHash` | Create hash grid |
| `gh:insert(pos, data)` | — | Insert entity at position |
| `gh:remove(pos)` | `boolean` | Remove by exact position |
| `gh:queryCell(pos)` | `{Entry}` | Entities in same cell |
| `gh:queryNeighbors(pos)` | `{Entry}` | Entities in 9-cell neighborhood |
| `gh:queryRadius(pos, r)` | `{Entry}` | Entities within radius |
| `gh:count()` | `number` | Total entities |
| `gh:clear()` | — | Remove all |

### SpatialHash

| Method | Returns | Description |
|--------|---------|-------------|
| `SpatialHash.new(cellSize)` | `SpatialHash` | Create spatial hash |
| `sh:insert(pos, radius, data)` | — | Insert sized entity |
| `sh:remove(pos, radius)` | — | Remove sized entity |
| `sh:queryRadius(pos, r)` | `{Entry}` | Find entities within radius |
| `sh:queryPotentialCollisions()` | `{{a, b}}` | All overlapping pairs |
| `sh:count()` | `number` | Total entities |
| `sh:clear()` | — | Remove all |

## Why This Over Roblox's Built-in SpatialQuery?

Roblox's `workspace:GetPartBoundsInRadius()` only works with `BasePart` instances. This works with **ANY data** — NPCs, items, particles, abstract entities. Pure math, no Instance overhead.

Use cases where luau-spatial shines:
- **Pathfinding AI**: Query neighbors for flocking, avoidance, or targeting
- **Projectile systems**: Broad-phase collision detection for hundreds of bullets
- **Proximity triggers**: Player-near-NPC detection without Region3/OverlapParams
- **Minimap/visibility culling**: Only render what's in the viewport
- **Abstract game logic**: Spatial queries on non-physical entities (spawn points, loot zones)

## Performance

| Structure | Insert | Query | Best For |
|-----------|--------|-------|----------|
| QuadTree | O(log n) | O(log n) | Non-uniform distributions (clustering) |
| GridHash | O(1) | O(n/cells) | Uniform distributions, fixed-size entities |
| SpatialHash | O(1) | O(1) avg | Variable-sized entities, broad-phase collision |

## License

MIT

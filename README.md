# luau-spatial

> Spatial indexing for Roblox games — 2D & 3D support with QuadTree/OcTree, GridHash, and SpatialHash.

## What This Does

Find what's near what, fast. Essential for collision detection, neighbor AI, proximity triggers, and rendering culling in Roblox games.

Now with **full 3D support** — `Vec3`, `BoundingBox3D`, and `OcTree` alongside the existing 2D structures.

Six modules, one goal: efficient spatial queries on ANY data — not just BaseParts.

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

Copy files from `src/` into your Roblox project as ModuleScripts. Make sure the parent-child hierarchy matches the `require` paths (Vec2, BoundingBox, QuadTree, GridHash, SpatialHash, Vec3, BoundingBox3D, OcTree all in the same folder).

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

### Vec3

| Method | Returns | Description |
|--------|---------|-------------|
| `Vec3.new(x, y, z)` | `Vec3` | Create a 3D vector |
| `Vec3.zero()` | `Vec3` | Zero vector |
| `v:length()` | `number` | Magnitude |
| `v:lengthSquared()` | `number` | Squared magnitude (no sqrt) |
| `v:distanceTo(other)` | `number` | Distance to another Vec3 |
| `v:distanceSquaredTo(other)` | `number` | Squared distance |
| `v:normalize()` | `Vec3` | Unit vector |
| `v:dot(other)` | `number` | Dot product |
| `v:cross(other)` | `Vec3` | Cross product |
| `v:add(other)` | `Vec3` | Vector addition |
| `v:sub(other)` | `Vec3` | Vector subtraction |
| `v:scale(s)` | `Vec3` | Scalar multiplication |
| `v:clone()` | `Vec3` | Copy |

### BoundingBox3D

| Method | Returns | Description |
|--------|---------|-------------|
| `BoundingBox3D.new(min, max)` | `BoundingBox3D` | Create from corners (Vec3) |
| `BoundingBox3D.fromCenter(center, halfW, halfH?, halfD?)` | `BoundingBox3D` | Create from center |
| `bb:contains(point)` | `boolean` | Point containment |
| `bb:intersects(other)` | `boolean` | Box intersection |
| `bb:containsSphere(center, radius)` | `boolean` | Sphere-box overlap |
| `bb:center()` | `Vec3` | Center point |
| `bb:width()` | `number` | Width |
| `bb:height()` | `number` | Height |
| `bb:depth()` | `number` | Depth |

### OcTree

| Method | Returns | Description |
|--------|---------|-------------|
| `OcTree.new(bounds, capacity?)` | `OcTree` | Create octree (default capacity: 8) |
| `ot:insert(pos, data)` | `boolean` | Insert point (false if out of bounds) |
| `ot:queryRadius(center, radius)` | `{Entry}` | Find entries within radius |
| `ot:queryBox(bounds)` | `{Entry}` | Find entries within bounding box |
| `ot:remove(pos)` | `boolean` | Remove by exact position |
| `ot:count()` | `number` | Total entries |
| `ot:clear()` | — | Remove all entries |

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

## Quick Start — 3D

### OcTree — Best for non-uniform 3D distributions

```luau
local OcTree = require(path.to.OcTree)
local BoundingBox3D = require(path.to.BoundingBox3D)
local Vec3 = require(path.to.Vec3)

-- Create a tree covering a 1000³ world
local tree = OcTree.new(BoundingBox3D.new(Vec3.new(0, 0, 0), Vec3.new(1000, 1000, 1000)))

-- Insert NPCs, items, projectiles, etc.
tree:insert(Vec3.new(50, 100, 200), npc1)
tree:insert(Vec3.new(200, 150, 300), npc2)

-- Find everything within 100 studs of the player (in 3D!)
local nearby = tree:queryRadius(playerPos3D, 100)
for _, entry in nearby do
    print(entry.data) -- your NPC/item data
end

-- Query within a bounding box
local results = tree:queryBox(BoundingBox3D.new(Vec3.new(0, 0, 0), Vec3.new(100, 100, 100)))

-- Remove something
tree:remove(pos3D)
```

### Vec3 — 3D vector math

```luau
local Vec3 = require(path.to.Vec3)

local a = Vec3.new(1, 2, 3)
local b = Vec3.new(4, 5, 6)

a:dot(b)       -- dot product
a:cross(b)     -- cross product
a:distanceTo(b) -- 3D distance
a:normalize()  -- unit vector
a:add(b)       -- vector addition
a:sub(b)       -- vector subtraction
a:scale(2)     -- scalar multiplication
```

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
| QuadTree | O(log n) | O(log n) | 2D non-uniform distributions (clustering) |
| OcTree | O(log n) | O(log n) | 3D non-uniform distributions (clustering) |
| GridHash | O(1) | O(n/cells) | Uniform distributions, fixed-size entities |
| SpatialHash | O(1) | O(1) avg | Variable-sized entities, broad-phase collision |

## License

MIT

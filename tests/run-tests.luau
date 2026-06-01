--[[
    Test runner for luau-spatial
    Simple test framework with no external dependencies.
    Run: luau tests/run-tests.luau
    (Or load as a Script in Roblox Studio)
]]

-- Simple test framework
local passed = 0
local failed = 0
local errors = {}

local function assert_(condition: boolean, message: string)
    if not condition then
        error(message, 2)
    end
end

local function assertEqual(actual: any, expected: any, label: string)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)), 2)
    end
end

local function assertApprox(actual: number, expected: number, tolerance: number, label: string)
    if math.abs(actual - expected) > tolerance then
        error(string.format("%s: expected ~%.4f, got %.4f", label, expected, actual), 2)
    end
end

type TestFn = () -> ()

local function test(name: string, fn: TestFn)
    local ok, err = pcall(fn)
    if ok then
        passed += 1
        print(string.format("  ✓ %s", name))
    else
        failed += 1
        print(string.format("  ✗ %s: %s", name, tostring(err)))
        table.insert(errors, { name = name, error = err })
    end
end

local function describe(suiteName: string, fn: () -> ())
    print(string.format("\n=== %s ===", suiteName))
    fn()
end

local function summary()
    print(string.format("\n━━━ Results: %d passed, %d failed, %d total ━━━", passed, failed, passed + failed))
    if #errors > 0 then
        print("\nFailures:")
        for _, e in errors do
            print(string.format("  • %s", e.name))
        end
    end
    return failed == 0
end

-- Load modules (adjust paths for Roblox or CLI)
local Vec2
local BoundingBox
local QuadTree
local GridHash
local SpatialHash

-- Try Roblox-style requires first, fall back to file paths
pcall(function()
    Vec2 = require(script.Parent.src.Vec2)
    BoundingBox = require(script.Parent.src.BoundingBox)
    QuadTree = require(script.Parent.src.QuadTree)
    GridHash = require(script.Parent.src.GridHash)
    SpatialHash = require(script.Parent.src.SpatialHash)
end)

if not Vec2 then
    Vec2 = require("../src/Vec2")
    BoundingBox = require("../src/BoundingBox")
    QuadTree = require("../src/QuadTree")
    GridHash = require("../src/GridHash")
    SpatialHash = require("../src/SpatialHash")
end

------------------------------------------------------
-- Vec2 Tests
------------------------------------------------------
describe("Vec2", function()
    test("creates a vector with correct components", function()
        local v = Vec2.new(3, 4)
        assertEqual(v.x, 3, "x")
        assertEqual(v.y, 4, "y")
    end)

    test("zero returns (0,0)", function()
        local v = Vec2.zero()
        assertEqual(v.x, 0, "x")
        assertEqual(v.y, 0, "y")
    end)

    test("length returns correct magnitude", function()
        local v = Vec2.new(3, 4)
        assertApprox(v:length(), 5, 0.0001, "length")
    end)

    test("distanceTo computes distance", function()
        local a = Vec2.new(0, 0)
        local b = Vec2.new(3, 4)
        assertApprox(a:distanceTo(b), 5, 0.0001, "distance")
    end)

    test("normalize returns unit vector", function()
        local v = Vec2.new(3, 4):normalize()
        assertApprox(v:length(), 1, 0.0001, "normalized length")
    end)

    test("normalize of zero vector returns zero", function()
        local v = Vec2.zero():normalize()
        assertEqual(v.x, 0, "x")
        assertEqual(v.y, 0, "y")
    end)

    test("dot product", function()
        local a = Vec2.new(1, 2)
        local b = Vec2.new(3, 4)
        assertEqual(a:dot(b), 11, "dot")
    end)

    test("add vectors", function()
        local r = Vec2.new(1, 2):add(Vec2.new(3, 4))
        assertEqual(r.x, 4, "x")
        assertEqual(r.y, 6, "y")
    end)

    test("sub vectors", function()
        local r = Vec2.new(5, 7):sub(Vec2.new(2, 3))
        assertEqual(r.x, 3, "x")
        assertEqual(r.y, 4, "y")
    end)

    test("scale vector", function()
        local r = Vec2.new(2, 3):scale(4)
        assertEqual(r.x, 8, "x")
        assertEqual(r.y, 12, "y")
    end)

    test("equality comparison", function()
        local a = Vec2.new(1, 2)
        local b = Vec2.new(1, 2)
        assert_(a == b, "vectors should be equal")
    end)

    test("tostring produces readable output", function()
        local s = tostring(Vec2.new(1, 2))
        assert_(s:find("Vec2") ~= nil, "should contain Vec2")
    end)
end)

------------------------------------------------------
-- BoundingBox Tests
------------------------------------------------------
describe("BoundingBox", function()
    test("contains point inside bounds", function()
        local bb = BoundingBox.new(Vec2.new(0, 0), Vec2.new(10, 10))
        assert_(bb:contains(Vec2.new(5, 5)), "should contain interior point")
    end)

    test("does not contain point outside bounds", function()
        local bb = BoundingBox.new(Vec2.new(0, 0), Vec2.new(10, 10))
        assert_(not bb:contains(Vec2.new(15, 15)), "should not contain exterior point")
    end)

    test("intersects overlapping boxes", function()
        local a = BoundingBox.new(Vec2.new(0, 0), Vec2.new(10, 10))
        local b = BoundingBox.new(Vec2.new(5, 5), Vec2.new(15, 15))
        assert_(a:intersects(b), "should intersect")
    end)

    test("non-intersecting boxes", function()
        local a = BoundingBox.new(Vec2.new(0, 0), Vec2.new(5, 5))
        local b = BoundingBox.new(Vec2.new(10, 10), Vec2.new(15, 15))
        assert_(not a:intersects(b), "should not intersect")
    end)

    test("fromCenter creates correct bounds", function()
        local bb = BoundingBox.fromCenter(Vec2.new(5, 5), 5)
        assertEqual(bb.min.x, 0, "min.x")
        assertEqual(bb.max.x, 10, "max.x")
    end)

    test("center returns correct center", function()
        local bb = BoundingBox.new(Vec2.new(0, 0), Vec2.new(10, 10))
        local c = bb:center()
        assertEqual(c.x, 5, "center.x")
        assertEqual(c.y, 5, "center.y")
    end)
end)

------------------------------------------------------
-- QuadTree Tests
------------------------------------------------------
describe("QuadTree", function()
    test("insert and count", function()
        local qt = QuadTree.new(BoundingBox.new(Vec2.new(0, 0), Vec2.new(100, 100)))
        qt:insert(Vec2.new(10, 10), "a")
        qt:insert(Vec2.new(20, 20), "b")
        assertEqual(qt:count(), 2, "count")
    end)

    test("insert out of bounds returns false", function()
        local qt = QuadTree.new(BoundingBox.new(Vec2.new(0, 0), Vec2.new(100, 100)))
        local ok = qt:insert(Vec2.new(200, 200), "x")
        assert_(not ok, "should reject out-of-bounds")
        assertEqual(qt:count(), 0, "count")
    end)

    test("queryBox returns matching entries", function()
        local qt = QuadTree.new(BoundingBox.new(Vec2.new(0, 0), Vec2.new(100, 100)))
        qt:insert(Vec2.new(10, 10), "a")
        qt:insert(Vec2.new(50, 50), "b")
        qt:insert(Vec2.new(90, 90), "c")

        local results = qt:queryBox(BoundingBox.new(Vec2.new(0, 0), Vec2.new(20, 20)))
        assertEqual(#results, 1, "should find 1 entry")
        assertEqual(results[1].data, "a", "data")
    end)

    test("queryRadius returns entries within radius", function()
        local qt = QuadTree.new(BoundingBox.new(Vec2.new(0, 0), Vec2.new(100, 100)))
        qt:insert(Vec2.new(10, 10), "a")
        qt:insert(Vec2.new(15, 15), "b")
        qt:insert(Vec2.new(90, 90), "c")

        local results = qt:queryRadius(Vec2.new(10, 10), 10)
        assertEqual(#results, 2, "should find 2 nearby entries")
    end)

    test("remove entry", function()
        local qt = QuadTree.new(BoundingBox.new(Vec2.new(0, 0), Vec2.new(100, 100)))
        local p = Vec2.new(10, 10)
        qt:insert(p, "a")
        assertEqual(qt:count(), 1, "before remove")
        qt:remove(p)
        assertEqual(qt:count(), 0, "after remove")
    end)

    test("subdivides when capacity exceeded", function()
        local qt = QuadTree.new(BoundingBox.new(Vec2.new(0, 0), Vec2.new(100, 100)), 2)
        qt:insert(Vec2.new(10, 10), "a")
        qt:insert(Vec2.new(20, 20), "b")
        qt:insert(Vec2.new(30, 30), "c") -- triggers subdivision
        assertEqual(qt:count(), 3, "count after subdivision")
        assert_(qt.divided, "should be divided")
    end)

    test("clear empties the tree", function()
        local qt = QuadTree.new(BoundingBox.new(Vec2.new(0, 0), Vec2.new(100, 100)))
        qt:insert(Vec2.new(10, 10), "a")
        qt:insert(Vec2.new(20, 20), "b")
        qt:clear()
        assertEqual(qt:count(), 0, "count after clear")
        assert_(not qt.divided, "should not be divided after clear")
    end)

    test("query empty tree returns empty", function()
        local qt = QuadTree.new(BoundingBox.new(Vec2.new(0, 0), Vec2.new(100, 100)))
        local results = qt:queryRadius(Vec2.new(50, 50), 50)
        assertEqual(#results, 0, "empty tree should return no results")
    end)

    test("many insertions maintain integrity", function()
        local qt = QuadTree.new(BoundingBox.new(Vec2.new(0, 0), Vec2.new(1000, 1000)), 4)
        for i = 1, 100 do
            qt:insert(Vec2.new(i * 10, i * 10), i)
        end
        assertEqual(qt:count(), 100, "count")
        local results = qt:queryRadius(Vec2.new(500, 500), 200)
        assert_(#results > 0, "should find some results")
    end)
end)

------------------------------------------------------
-- GridHash Tests
------------------------------------------------------
describe("GridHash", function()
    test("insert and queryCell", function()
        local gh = GridHash.new(10)
        gh:insert(Vec2.new(15, 25), "a")
        local results = gh:queryCell(Vec2.new(15, 25))
        assertEqual(#results, 1, "should find 1 entry")
        assertEqual(results[1].data, "a", "data")
    end)

    test("queryCell empty cell returns empty", function()
        local gh = GridHash.new(10)
        gh:insert(Vec2.new(15, 25), "a")
        local results = gh:queryCell(Vec2.new(95, 95))
        assertEqual(#results, 0, "empty cell")
    end)

    test("queryNeighbors returns 9-cell neighborhood", function()
        local gh = GridHash.new(10)
        gh:insert(Vec2.new(15, 15), "center")
        gh:insert(Vec2.new(25, 15), "right")
        gh:insert(Vec2.new(5, 5), "far")

        local results = gh:queryNeighbors(Vec2.new(15, 15))
        assert_(#results >= 2, "should find center and right")
    end)

    test("queryRadius filters by distance", function()
        local gh = GridHash.new(10)
        gh:insert(Vec2.new(10, 10), "near")
        gh:insert(Vec2.new(50, 50), "far")

        local results = gh:queryRadius(Vec2.new(10, 10), 5)
        assertEqual(#results, 1, "should find only near entry")
        assertEqual(results[1].data, "near", "data")
    end)

    test("remove entry", function()
        local gh = GridHash.new(10)
        local p = Vec2.new(15, 25)
        gh:insert(p, "a")
        assertEqual(gh:count(), 1, "before remove")
        gh:remove(p)
        assertEqual(gh:count(), 0, "after remove")
    end)

    test("remove nonexistent returns false", function()
        local gh = GridHash.new(10)
        local ok = gh:remove(Vec2.new(99, 99))
        assert_(not ok, "should return false")
    end)

    test("clear empties the hash", function()
        local gh = GridHash.new(10)
        gh:insert(Vec2.new(10, 10), "a")
        gh:insert(Vec2.new(20, 20), "b")
        gh:clear()
        assertEqual(gh:count(), 0, "count after clear")
    end)
end)

------------------------------------------------------
-- SpatialHash Tests
------------------------------------------------------
describe("SpatialHash", function()
    test("insert and count", function()
        local sh = SpatialHash.new(50)
        sh:insert(Vec2.new(10, 10), 5, "a")
        sh:insert(Vec2.new(60, 60), 10, "b")
        assertEqual(sh:count(), 2, "count")
    end)

    test("queryRadius finds overlapping entities", function()
        local sh = SpatialHash.new(50)
        sh:insert(Vec2.new(25, 25), 10, "a")
        sh:insert(Vec2.new(30, 30), 10, "b")
        sh:insert(Vec2.new(200, 200), 5, "c")

        local results = sh:queryRadius(Vec2.new(25, 25), 15)
        assert_(#results >= 1, "should find at least 1 entity")
    end)

    test("queryRadius respects entity size", function()
        local sh = SpatialHash.new(50)
        sh:insert(Vec2.new(0, 0), 50, "big")
        -- Entity center is at (0,0) with radius 50, query at (40,0) with radius 20
        -- Distance = 40, combined radius = 70 → should overlap
        local results = sh:queryRadius(Vec2.new(40, 0), 20)
        assertEqual(#results, 1, "should find big entity via combined radius")
    end)

    test("queryPotentialCollisions detects pairs", function()
        local sh = SpatialHash.new(50)
        sh:insert(Vec2.new(10, 10), 10, "a")
        sh:insert(Vec2.new(15, 15), 10, "b")
        sh:insert(Vec2.new(200, 200), 5, "c")

        local pairs = sh:queryPotentialCollisions()
        assert_(#pairs >= 1, "should find collision pair")
        -- a and b should collide (distance ~7, combined radius 20)
    end)

    test("queryPotentialCollisions returns empty for no collisions", function()
        local sh = SpatialHash.new(50)
        sh:insert(Vec2.new(0, 0), 5, "a")
        sh:insert(Vec2.new(200, 200), 5, "b")

        local pairs = sh:queryPotentialCollisions()
        assertEqual(#pairs, 0, "no collisions expected")
    end)

    test("remove entity", function()
        local sh = SpatialHash.new(50)
        sh:insert(Vec2.new(10, 10), 5, "a")
        assertEqual(sh:count(), 1, "before remove")
        sh:remove(Vec2.new(10, 10), 5)
        assertEqual(sh:count(), 0, "after remove")
    end)

    test("clear empties the hash", function()
        local sh = SpatialHash.new(50)
        sh:insert(Vec2.new(10, 10), 5, "a")
        sh:insert(Vec2.new(20, 20), 10, "b")
        sh:clear()
        assertEqual(sh:count(), 0, "count after clear")
    end)
end)

------------------------------------------------------
-- Edge Cases
------------------------------------------------------
describe("Edge Cases", function()
    test("duplicate positions in QuadTree", function()
        local qt = QuadTree.new(BoundingBox.new(Vec2.new(0, 0), Vec2.new(100, 100)))
        qt:insert(Vec2.new(10, 10), "a")
        qt:insert(Vec2.new(10, 10), "b")
        assertEqual(qt:count(), 2, "should store both")
    end)

    test("GridHash with very small cell size", function()
        local gh = GridHash.new(0.1)
        gh:insert(Vec2.new(0.05, 0.05), "a")
        assertEqual(gh:count(), 1, "count")
    end)

    test("SpatialHash single entity no self-collision", function()
        local sh = SpatialHash.new(50)
        sh:insert(Vec2.new(10, 10), 10, "a")
        local pairs = sh:queryPotentialCollisions()
        assertEqual(#pairs, 0, "single entity should not collide with itself")
    end)

    test("QuadTree queryRadius on boundary", function()
        local qt = QuadTree.new(BoundingBox.new(Vec2.new(0, 0), Vec2.new(100, 100)))
        qt:insert(Vec2.new(100, 100), "corner")
        local results = qt:queryRadius(Vec2.new(95, 95), 10)
        assert_(#results >= 1, "should find corner entry")
    end)
end)

-- Run summary
summary()

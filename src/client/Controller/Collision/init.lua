-- Collision.lua
-- Fires raycasts each frame to detect ground, walls, and ceiling.
-- Returns a contact table that Physics.lua uses to make decisions.
-- Never modifies velocity or state — detection only.
--
-- PLACEMENT: ModuleScript, child of Controller.lua

local Config = require(script.Parent.Config)

local Collision = {}

-- ─── Raycast filter ───────────────────────────────────────────────────────────
-- Excludes the character's own parts from hitting itself.
-- Set this up in Controller.lua after the character loads.

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

function Collision.setCharacter(characterModel)
    raycastParams.FilterDescendantsInstances = { characterModel }
end

-- ─── Helpers ──────────────────────────────────────────────────────────────────

local function cast(origin, direction)
    return workspace:Raycast(origin, direction, raycastParams)
end

-- ─── Main detection ───────────────────────────────────────────────────────────
-- rootPos: Vector3 — the character's HumanoidRootPart position this frame.
-- Returns a contact table.

function Collision.check(rootPos)
    local hw = Config.CHAR_HALF_WIDTH
    local hh = Config.CHAR_HALF_HEIGHT

    -- ── Ground ────────────────────────────────────────────────────────────────
    -- Three downward rays: center, left edge, right edge.
    -- Any hit counts as grounded. Using three prevents missing narrow edges.
    local groundOrigin = rootPos + Vector3.new(0, -hh + 0.1, 0)
    local groundDir    = Vector3.new(0, -Config.GROUND_RAY_LEN, 0)

    local groundHit =
        cast(groundOrigin, groundDir) or
        cast(groundOrigin + Vector3.new( hw * 0.8, 0, 0), groundDir) or
        cast(groundOrigin + Vector3.new(-hw * 0.8, 0, 0), groundDir)

    local grounded    = groundHit ~= nil
    local groundY     = grounded and groundHit.Position.Y or nil
    local groundNormal = grounded and groundHit.Normal or Vector3.yAxis

    -- ── Walls ─────────────────────────────────────────────────────────────────
    -- Two rays per side at different heights to catch partial wall contacts.
    local midY  = rootPos.Y
    local highY = rootPos.Y + hh * 0.5

    local wallRightHit =
        cast(Vector3.new(rootPos.X, midY,  rootPos.Z), Vector3.new( Config.WALL_RAY_LEN, 0, 0)) or
        cast(Vector3.new(rootPos.X, highY, rootPos.Z), Vector3.new( Config.WALL_RAY_LEN, 0, 0))

    local wallLeftHit =
        cast(Vector3.new(rootPos.X, midY,  rootPos.Z), Vector3.new(-Config.WALL_RAY_LEN, 0, 0)) or
        cast(Vector3.new(rootPos.X, highY, rootPos.Z), Vector3.new(-Config.WALL_RAY_LEN, 0, 0))

    -- wallDir: 1 = wall on right, -1 = wall on left, 0 = no wall
    local wallDir = 0
    if wallRightHit then wallDir =  1 end
    if wallLeftHit  then wallDir = -1 end
    -- If both somehow hit, prefer the one the player is moving into (handled in Controller).

    -- ── Ceiling ───────────────────────────────────────────────────────────────
    local ceilOrigin = rootPos + Vector3.new(0, hh - 0.1, 0)
    local ceilHit    = cast(ceilOrigin, Vector3.new(0, Config.CEIL_RAY_LEN, 0))

    return {
        grounded      = grounded,
        groundY       = groundY,       -- Y position of ground surface (for snapping)
        groundNormal  = groundNormal,  -- surface normal (useful for slopes later)
        wallDir       = wallDir,       -- 1, -1, or 0
        wallRightHit  = wallRightHit ~= nil,
        wallLeftHit   = wallLeftHit  ~= nil,
        ceilingHit    = ceilHit ~= nil,
    }
end

return Collision
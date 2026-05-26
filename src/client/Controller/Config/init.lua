-- Config.lua
-- All tunable constants for the Mega Man controller.
-- Every other module requires this. Nothing writes to it at runtime.
--
-- PLACEMENT: ModuleScript, child of Controller.lua

local Config = {}

-- ─── Movement ────────────────────────────────────────────────────────────────

Config.MOVE_SPEED       = 18      -- horizontal studs/sec while running
Config.MOVE_ACCEL       = 0       -- 0 = instant, >0 = frames to reach full speed (not yet used)

-- ─── Jump ────────────────────────────────────────────────────────────────────

Config.JUMP_POWER       = 62      -- initial upward velocity on jump
Config.JUMP_CUT_MULT    = 0.45    -- fraction of upward vel kept when jump released early
Config.APEX_THRESHOLD   = 8       -- velY below this (near peak) gets apex gravity
Config.APEX_GRAV_MULT   = 0.55    -- gravity multiplier at apex (floatier peak)

-- ─── Gravity ─────────────────────────────────────────────────────────────────

Config.GRAVITY          = 140     -- studs/sec² base downward acceleration
Config.FALL_MULT        = 2.1     -- extra gravity multiplier while falling (velY < 0)
Config.MAX_FALL_SPEED   = -80     -- terminal velocity (negative = downward)

-- ─── Coyote time & jump buffer ───────────────────────────────────────────────

Config.COYOTE_TIME      = 0.10    -- seconds after leaving a ledge you can still jump
Config.JUMP_BUFFER_TIME = 0.12    -- seconds a jump press is remembered before landing

-- ─── Dash (Mega Man X style) ─────────────────────────────────────────────────

Config.DASH_SPEED       = 36      -- horizontal studs/sec during dash
Config.DASH_DURATION    = 0.18    -- seconds the dash lasts
Config.DASH_COOLDOWN    = 0.05    -- seconds after dash ends before another is allowed

-- ─── Wall slide & wall jump ──────────────────────────────────────────────────

Config.WALL_SLIDE_SPEED = -5      -- max downward speed while sliding a wall (negative)
Config.WALL_JUMP_POWER  = 58      -- upward velocity on wall jump
Config.WALL_JUMP_KICK   = 22      -- horizontal kick away from wall on wall jump
Config.WALL_CONTROL_LOCK = 0.15   -- seconds of reduced air control after wall jump

-- ─── Collision raycasts ──────────────────────────────────────────────────────

Config.GROUND_RAY_LEN   = 3.2     -- length of downward ground-check ray (studs)
Config.WALL_RAY_LEN     = 1.8     -- length of left/right wall-check rays
Config.CEIL_RAY_LEN     = 2.0     -- length of upward ceiling-check ray
Config.GROUND_SNAP      = 0.15    -- snap-to-ground threshold when landing

-- ─── Character size (adjust to match your rig) ───────────────────────────────

Config.CHAR_HALF_WIDTH  = 1.0     -- half the character's width for wall ray origins
Config.CHAR_HALF_HEIGHT = 2.5     -- half the character's height for ray origins

-- ─── Miscellaneous ───────────────────────────────────────────────────────────

Config.Z_LOCK           = 0       -- Z position the character is locked to (2.5D)
Config.SHOOT_COOLDOWN   = 0.15    -- minimum seconds between buster shots

return Config
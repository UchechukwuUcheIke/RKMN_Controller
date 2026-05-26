-- Physics.lua
-- Computes the character's velocity each frame based on input, collision,
-- and current state. Returns a Vector3. Never touches the RootPart directly.
--
-- Implements:
--   • Variable jump height (jump cut on release)
--   • Asymmetric gravity (fall faster than rise)
--   • Apex gravity reduction (floatier peak)
--   • Wall slide slow fall
--   • Dash burst (gravity-locked)
--   • Wall jump kick
--
-- PLACEMENT: ModuleScript, child of Controller.lua

local Config = require(script.Parent.Config)

local Physics = {}

-- ─── Persistent velocity ──────────────────────────────────────────────────────
-- velY persists across frames. velX does NOT (Mega Man has instant acceleration).

local velY = 0

-- ─── Public: reset ────────────────────────────────────────────────────────────

function Physics.reset()
    velY = 0
end

-- ─── Public: read current velY (for State transitions) ───────────────────────

function Physics.getVelY()
    return velY
end

-- ─── Main solve ───────────────────────────────────────────────────────────────
-- Called every Heartbeat. Returns Vector3 velocity for this frame.
--
-- actions : table from Input.get()
-- contact : table from Collision.check()
-- state   : State module (read-only here)
-- dt      : delta time from Heartbeat

function Physics.solve(actions, contact, state, dt)

    -- ── Horizontal ────────────────────────────────────────────────────────────

    local velX = 0

    if state.current == "Dash" then
        -- During a dash, horizontal speed is fixed; ignore moveX.
        velX = state.facingDir * Config.DASH_SPEED

    elseif state.current == "WallJump" then
        -- Brief control lock after wall jump. After WALL_CONTROL_LOCK seconds,
        -- the player regains full air control. Before that, kick velocity only.
        if state.timer < Config.WALL_CONTROL_LOCK then
            velX = -state.wallDir * Config.WALL_JUMP_KICK
        else
            velX = actions.moveX * Config.MOVE_SPEED
        end

    else
        velX = actions.moveX * Config.MOVE_SPEED
    end

    -- ── Vertical ──────────────────────────────────────────────────────────────

    if state.current == "Dash" then
        -- Dash ignores gravity entirely for its duration.
        velY = 0

    elseif contact.grounded and velY <= 0 then
        -- On the ground: kill downward velocity, allow jump.
        velY = 0

        if actions.jumpBuffered then
            -- Normal ground jump
            velY = Config.JUMP_POWER
            Input_consumeJump()   -- signal handled below via return flag
        end

    else
        -- Airborne gravity
        local gravMult = 1.0

        if velY < 0 then
            -- Falling: extra gravity for snappy drop
            gravMult = Config.FALL_MULT

        elseif velY > 0 and velY < Config.APEX_THRESHOLD then
            -- Near the apex: reduced gravity for a floatier peak
            gravMult = Config.APEX_GRAV_MULT

        elseif velY > 0 and not actions.jumpHeld then
            -- Jump cut: player released jump early, reduce upward velocity
            velY = velY * Config.JUMP_CUT_MULT
            -- Only apply once by clamping — if already low, fall mult takes over
        end

        velY = velY - Config.GRAVITY * gravMult * dt

        -- Coyote jump: jumped within the coyote window after leaving a ledge
        if actions.jumpBuffered and actions.canCoyote and velY < 0 then
            velY = Config.JUMP_POWER
        end

        -- Wall jump: launched this frame from WallJump state entry
        if state.current == "WallJump" and state.timer < dt * 2 then
            velY = Config.WALL_JUMP_POWER
        end

        -- Ceiling: cut upward velocity if head hits something
        if contact.ceilingHit and velY > 0 then
            velY = 0
        end

        -- Wall slide: clamp downward speed while pressed against a wall
        if state.current == "WallSlide" then
            velY = math.max(velY, Config.WALL_SLIDE_SPEED)
        end

        -- Terminal velocity
        velY = math.max(velY, Config.MAX_FALL_SPEED)
    end

    -- ── Z lock (2.5D) ─────────────────────────────────────────────────────────
    -- Z is never touched; the Controller will enforce it on the CFrame.

    return Vector3.new(velX, velY, 0), actions.jumpBuffered and contact.grounded
end

-- ─── Note on Input_consumeJump ────────────────────────────────────────────────
-- Physics.solve returns a second boolean (didJump) so Controller can call
-- Input.consumeJump() without Physics needing a reference to Input.
-- Keep the dependency graph clean: Physics reads data, never calls siblings.

return Physics
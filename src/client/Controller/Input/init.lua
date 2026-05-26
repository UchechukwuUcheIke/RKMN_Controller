local MOVE_SPEED   = 16   -- studs/sec (X speed)
local JUMP_POWER   = 50   -- initial Y velocity
local GRAVITY      = 120  -- studs/sec² (manual gravity)
local FALL_MULT    = 2.2  -- fall faster than rising
local RISE_CUT     = 0.5  -- cut rise if jump released early
local COYOTE_TIME  = 0.1  -- seconds after ledge you can still jump
local WALL_SLIDE_V = -4   -- slow fall while wall-sliding

local velY = 0
local coyoteTimer = 0

function Resolver.resolve(state, actions, contact, dt)
    -- Horizontal
    local vx = actions.moveX * MOVE_SPEED
    if state == "Dash" then vx = actions.facing * 28 end

    -- Vertical / gravity
    if contact.grounded then
        coyoteTimer = COYOTE_TIME
        velY = 0
        if actions.jumpPressed then velY = JUMP_POWER end
    else
        coyoteTimer -= dt
        -- Jump cut: releasing jump button halves upward velocity
        if velY > 0 and not actions.jumpHeld then
            velY -= GRAVITY * RISE_CUT * dt
        else
            local mult = velY < 0 and FALL_MULT or 1
            velY -= GRAVITY * mult * dt
        end
        -- Coyote jump
        if actions.jumpPressed and coyoteTimer > 0 then
            velY = JUMP_POWER
            coyoteTimer = 0
        end
        -- Wall slide
        if state == "WallSlide" then
            velY = math.max(velY, WALL_SLIDE_V)
        end
    end

    return Vector3.new(vx, velY, 0)
end
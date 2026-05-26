-- Input.lua
-- Reads UserInputService and gamepad each frame.
-- Handles jump buffering so a press slightly before landing still registers.
-- Coyote time countdown is managed here and read by Physics.lua.
--
-- PLACEMENT: ModuleScript, child of Controller.lua

local UserInputService = game:GetService("UserInputService")
local Config = require(script.Parent.Config)

local Input = {}

-- ─── Internal state ───────────────────────────────────────────────────────────

local jumpBufferTimer  = 0     -- counts down; >0 means a jump was recently pressed
local coyoteTimer      = 0     -- counts down; >0 means recently left the ground
local dashPressed      = false -- consumed each frame
local shootPressed     = false -- consumed each frame
local jumpConsumed     = false -- prevents holding jump from re-triggering

-- ─── Key bindings ─────────────────────────────────────────────────────────────
-- Swap these out for your preferred layout.

local KB = {
    left    = { Enum.KeyCode.A, Enum.KeyCode.Left  },
    right   = { Enum.KeyCode.D, Enum.KeyCode.Right },
    jump    = { Enum.KeyCode.Space, Enum.KeyCode.Z  },
    dash    = { Enum.KeyCode.LeftShift, Enum.KeyCode.X },
    shoot   = { Enum.KeyCode.F, Enum.KeyCode.C },
}

-- ─── Helpers ──────────────────────────────────────────────────────────────────

local function anyDown(keys)
    for _, key in ipairs(keys) do
        if UserInputService:IsKeyDown(key) then return true end
    end
    return false
end

-- ─── InputBegan: one-shot events ──────────────────────────────────────────────

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Jump buffer: remember the press for JUMP_BUFFER_TIME seconds
    for _, key in ipairs(KB.jump) do
        if input.KeyCode == key then
            jumpBufferTimer = Config.JUMP_BUFFER_TIME
            jumpConsumed    = false
        end
    end

    -- Dash (one-shot on press, not held)
    for _, key in ipairs(KB.dash) do
        if input.KeyCode == key then
            dashPressed = true
        end
    end

    -- Shoot (one-shot)
    for _, key in ipairs(KB.shoot) do
        if input.KeyCode == key then
            shootPressed = true
        end
    end
end)

-- ─── Public API ───────────────────────────────────────────────────────────────

-- Call once per Heartbeat. Returns a snapshot of this frame's input.
-- dt is used to tick down the buffer/coyote timers.
function Input.get(dt)
    jumpBufferTimer = math.max(0, jumpBufferTimer - dt)
    coyoteTimer     = math.max(0, coyoteTimer     - dt)

    local moveX = 0
    if anyDown(KB.right) then moveX = moveX + 1 end
    if anyDown(KB.left)  then moveX = moveX - 1 end

    local jumpHeld      = anyDown(KB.jump)
    local jumpBuffered  = jumpBufferTimer > 0 and not jumpConsumed
    local canCoyote     = coyoteTimer > 0

    -- Consume one-shot flags
    local dash  = dashPressed;  dashPressed  = false
    local shoot = shootPressed; shootPressed = false

    return {
        moveX       = moveX,           -- -1, 0, or 1
        jumpHeld    = jumpHeld,         -- true while jump key is held (for jump cut)
        jumpBuffered = jumpBuffered,    -- true if a recent jump press is pending
        canCoyote   = canCoyote,        -- true if coyote window is open
        dashPressed = dash,             -- true for exactly one frame
        shootPressed = shoot,           -- true for exactly one frame
    }
end

-- Call this when the character leaves the ground to start the coyote window.
function Input.startCoyote()
    coyoteTimer = Config.COYOTE_TIME
end

-- Call this when a jump is consumed so the buffer doesn't re-fire.
function Input.consumeJump()
    jumpBufferTimer = 0
    jumpConsumed    = true
end

-- Call this to reset coyote (e.g. after a wall jump or mid-air dash start).
function Input.resetCoyote()
    coyoteTimer = 0
end

return Input
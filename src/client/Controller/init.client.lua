-- Controller.lua
-- The orchestrator. Runs every Heartbeat, calls each module in order,
-- resolves state transitions, and writes the final velocity to the RootPart.
--
-- Module dependency graph (no cycles):
--
--   Controller
--     ├── requires Config   (constants)
--     ├── requires State    (current state + metadata)
--     ├── requires Input    (actions this frame)
--     ├── requires Collision (contact data this frame)
--     └── requires Physics  (velocity computation)
--
-- PLACEMENT: LocalScript inside StarterCharacterScripts.
--   Physics, Collision, Input, State, Config are ModuleScript children of this script.

local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")

local Config    = require(script.Config)
local State     = require(script.State)
local Input     = require(script.Input)
local Collision = require(script.Collision)
local Physics   = require(script.Physics)

-- ─── Wait for character ───────────────────────────────────────────────────────

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root      = character:WaitForChild("HumanoidRootPart")
local humanoid  = character:WaitForChild("Humanoid")

-- ─── Initial setup ────────────────────────────────────────────────────────────

-- Tell Collision to exclude this character from its raycasts.
Collision.setCharacter(character)

-- Stop the Humanoid from fighting our velocity.
-- We take full control of movement.
humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,  false)
humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed,   false)
humanoid:ChangeState(Enum.HumanoidStateType.Physics)

-- ─── Animation setup ──────────────────────────────────────────────────────────
-- Replace the animation IDs below with your own assets.
-- Tracks are pre-loaded once at startup to avoid per-frame loading.

local animator = humanoid:WaitForChild("Animator")

local ANIM_IDS = {
    Idle      = "rbxassetid://0",   -- replace with real IDs
    Run       = "rbxassetid://0",
    Jump      = "rbxassetid://0",
    Fall      = "rbxassetid://0",
    Dash      = "rbxassetid://0",
    WallSlide = "rbxassetid://0",
    WallJump  = "rbxassetid://0",
    Shoot     = "rbxassetid://0",   -- layered on top of movement anims
}

local tracks = {}
for stateName, assetId in pairs(ANIM_IDS) do
    local anim = Instance.new("Animation")
    anim.AnimationId = assetId
    tracks[stateName] = animator:LoadAnimation(anim)
end

local currentTrack = nil

local function driveAnimation(stateName)
    local track = tracks[stateName] or tracks["Idle"]
    if currentTrack ~= track then
        if currentTrack then currentTrack:Stop(0.08) end
        track:Play(0.05)
        currentTrack = track
    end
    -- Layered shoot animation (plays over the base track)
    if State.isShooting and tracks["Shoot"] and not tracks["Shoot"].IsPlaying then
        tracks["Shoot"]:Play(0.03)
    elseif not State.isShooting and tracks["Shoot"] and tracks["Shoot"].IsPlaying then
        tracks["Shoot"]:Stop(0.05)
    end
end

-- ─── Facing direction ─────────────────────────────────────────────────────────

local function updateFacing(moveX)
    if moveX ~= 0 then
        State.facingDir = moveX > 0 and 1 or -1
    end
end

local function applyFacing()
    -- Flip the model on the Y axis to face the right direction.
    -- Adjust the base CFrame angle if your rig faces a different default direction.
    root.CFrame = CFrame.new(root.Position)
        * CFrame.Angles(0, State.facingDir == 1 and 0 or math.pi, 0)
end

-- ─── State transition logic ───────────────────────────────────────────────────
-- Only Controller decides when to change state.
-- Called after Physics.solve so velY is current.

local function resolveState(actions, contact, didJump)
    local s   = State.current
    local velY = Physics.getVelY()

    -- ── Transitions that can happen from most states ──────────────────────────

    -- Dash takes priority (only if canDash and not already dashing)
    if actions.dashPressed and State.canDash and s ~= "Dash" then
        State.canDash = false
        State.set("Dash")
        return
    end

    -- ── Per-state transitions ─────────────────────────────────────────────────

    if s == "Idle" or s == "Run" then
        if not contact.grounded then
            -- Walked off a ledge
            Input.startCoyote()
            State.set("Fall")
        elseif actions.moveX ~= 0 then
            State.set("Run")
        else
            State.set("Idle")
        end
        if didJump then State.set("Jump") end

    elseif s == "Jump" then
        if contact.wallDir ~= 0 and velY < 0 then
            State.wallDir = contact.wallDir
            State.set("WallSlide")
        elseif velY <= 0 then
            State.set("Fall")
        end

    elseif s == "Fall" then
        if contact.grounded then
            State.canDash = true
            State.set(actions.moveX ~= 0 and "Run" or "Idle")
        elseif contact.wallDir ~= 0 then
            State.wallDir = contact.wallDir
            State.set("WallSlide")
        elseif actions.jumpBuffered and actions.canCoyote then
            Input.consumeJump()
            Input.resetCoyote()
            State.set("Jump")
        end

    elseif s == "WallSlide" then
        if contact.grounded then
            State.canDash = true
            Input.resetCoyote()
            State.set("Idle")
        elseif contact.wallDir == 0 then
            -- Slid off the bottom of the wall
            State.set("Fall")
        elseif actions.jumpBuffered then
            Input.consumeJump()
            State.set("WallJump")
        end

    elseif s == "WallJump" then
        -- After control lock expires, treat like a normal jump
        if State.timer >= Config.WALL_CONTROL_LOCK then
            if velY <= 0 then State.set("Fall") end
            if contact.wallDir ~= 0 and velY < 0 then
                State.wallDir = contact.wallDir
                State.set("WallSlide")
            end
        end

    elseif s == "Dash" then
        if State.timer >= Config.DASH_DURATION then
            State.set(contact.grounded and "Idle" or "Fall")
        end
    end
end

-- ─── Main Heartbeat loop ──────────────────────────────────────────────────────

RunService.Heartbeat:Connect(function(dt)
    -- 1. Tick state timer
    State.tick(dt)

    -- 2. Read input
    local actions = Input.get(dt)

    -- 3. Update facing before physics so dash uses the right direction
    updateFacing(actions.moveX)

    -- 4. Check collisions
    local contact = Collision.check(root.Position)

    -- 5. Solve velocity
    local velocity, didJump = Physics.solve(actions, contact, State, dt)

    if didJump then
        Input.consumeJump()
        State.set("Jump")
    end

    -- 6. Handle shooting
    if actions.shootPressed and State.shootTimer <= 0 then
        State.isShooting = true
        State.shootTimer  = Config.SHOOT_COOLDOWN
        -- TODO: spawn your buster projectile here, e.g.:
        -- Projectile.spawn(root.Position, State.facingDir)
    else
        -- Shooting flag clears after one animation cycle (tied to shootTimer)
        State.isShooting = State.shootTimer > 0
    end

    -- 7. Resolve state transitions
    resolveState(actions, contact, didJump)

    -- 8. Apply velocity to the RootPart
    --    AssemblyLinearVelocity is immediate — no Humanoid interference.
    root.AssemblyLinearVelocity = velocity

    -- 9. Lock Z position (enforce 2.5D)
    --    Move the root to its current position with Z snapped.
    if math.abs(root.Position.Z - Config.Z_LOCK) > 0.01 then
        root.CFrame = CFrame.new(
            root.Position.X,
            root.Position.Y,
            Config.Z_LOCK
        ) * (root.CFrame - root.CFrame.Position)
    end

    -- 10. Flip model to face correct direction
    applyFacing()

    -- 11. Drive animations
    driveAnimation(State.current)
end)

-- ─── Character respawn ────────────────────────────────────────────────────────
-- If the character dies and respawns, this LocalScript is replaced automatically
-- because it lives in StarterCharacterScripts. No manual cleanup needed.
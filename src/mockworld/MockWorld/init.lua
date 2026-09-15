

local MockWorld = {}

export type MockWorld = typeof(setmetatable(
    {} :: {
		_viewport: ViewportFrame,
        _world: WorldModel,
    },
    {} :: typeof(MockWorld)
))

export type Properties = {
    Size: Vector3?,
    Position: Vector3?,
    CFrame: CFrame?,
}

-- The __index function for method routing
local function index(t, key)
    if MockWorld[key] then
        return MockWorld[key]
    end

    local classMember: any = t._world[key]
    local isMethod: boolean = type(classMember) == "function"
    
    if isMethod then
	-- This will create a new function every time one of WorldModel method is called
-- Ideally we should cache the function into MockWorld directly
-- See https://www.lua.org/pil/16.3.html
        return function(_, ...)
            return classMember(t._world, ...)
        end
    end

    return classMember
end

function MockWorld.new(): MockWorld
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PreviewGui"
	screenGui.Parent = playerGui

	local viewport = Instance.new("ViewportFrame")
    viewport.Parent = screenGui
	local world = Instance.new("WorldModel")
	world.Parent = viewport

    -- The __index function goes into the metatable itself
    local self = setmetatable({
		_screengui = screenGui,
		_viewport = viewport,
        _world = world
    }, {
        __index = index 
    })

    return self :: MockWorld
end

function MockWorld:SpawnPart(properties: Properties?): Part    
    local part: Part = self:_spawnInstance("Part", properties) :: Part
    part.Anchored = true
    return part
end

function MockWorld:SpawnCharacter(): Model
    local characterModel: Model = self:_spawnInstance("Model") :: Model
    local properties: Properties = { Size = Vector3.new(2, 2, 1) }
    local humanoidRootPart = self:_spawnHumanoidRootPart(properties)
    humanoidRootPart.Parent = characterModel
    characterModel.PrimaryPart = humanoidRootPart
    
    local humanoid = self:_spawnInstance("Humanoid")
    humanoid.Parent = characterModel
    
    return characterModel
end

function MockWorld:Clear(): ()
    self._world:ClearAllChildren()
end 

function MockWorld:Destroy(): ()
    if self._screengui then
        self._screengui:Destroy()
		self._screengui = nil
        self._viewport = nil
		self._world = nil
    end
end

function MockWorld:_spawnHumanoidRootPart(properties: Properties): Part
    local humanoidRootPart = self:SpawnPart(properties)
    humanoidRootPart.Name = "HumanoidRootPart"
    return humanoidRootPart
end

local function setInstanceProperties(instance: Instance, properties: Properties): ()
    for key, value in pairs(properties) do
        local success: boolean = pcall(function()
            instance[key] = value
        end)

		if not success then
        	warn(string.format("Attempted to set invalid property '%s' on %s", key, instance.ClassName))
		end
    end
end

function MockWorld:_addInstanceToWorld(instance: Instance): ()
    instance.Parent = self._world
end

function MockWorld:_spawnInstance(className: string, properties: Properties?): Instance
    local instance: Instance = Instance.new(className)
    
    if properties then
        setInstanceProperties(instance, properties)
    end
    
    self:_addInstanceToWorld(instance)
    return instance
end


return MockWorld

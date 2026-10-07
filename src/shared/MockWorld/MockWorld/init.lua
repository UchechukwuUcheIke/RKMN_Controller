local MockWorld = {}

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

MockWorld.__index = index

type MockWorldData = {
	_surface_part: BasePart,
    _world: WorldModel,
}

export type MockWorld = typeof(setmetatable(
    {} :: MockWorldData,
    MockWorld
))

export type Properties = {
    Size: Vector3?,
    Position: Vector3?,
    CFrame: CFrame?,
}



function MockWorld.new(): MockWorld
	local part = Instance.new("Part")
    part.Parent = game.Workspace
    part.Anchored = true

	local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Parent = part
    surfaceGui.Adornee = part
	surfaceGui.Name = "PreviewGui"

	local viewport = Instance.new("ViewportFrame")
    viewport.Parent = surfaceGui
	local world = Instance.new("WorldModel")
	world.Parent = viewport

    local self = setmetatable({
		_surface_part = part,
        _world = world
    }, MockWorld)

    return self :: MockWorld
end

function MockWorld.SpawnPart(self: MockWorld, properties: Properties?): Part    
    local part: Part = self:_spawnInstance("Part", properties) :: Part
    part.Anchored = true
    return part
end

function MockWorld.SpawnCharacter(self: MockWorld): Model
    local characterModel: Model = self:_spawnInstance("Model") :: Model
    local properties: Properties = { Size = Vector3.new(2, 2, 1) }
    local humanoidRootPart = self:_spawnHumanoidRootPart(properties)
    humanoidRootPart.Parent = characterModel
    characterModel.PrimaryPart = humanoidRootPart
    
    local humanoid = self:_spawnInstance("Humanoid")
    humanoid.Parent = characterModel
    
    return characterModel
end

function MockWorld.Clear(self: MockWorld): ()
    self._world:ClearAllChildren()
end 

function MockWorld.Destroy(self: MockWorld): ()
    if self._surface_part then
        self._surface_part:Destroy()
    end
end

function MockWorld._spawnHumanoidRootPart(self: MockWorld, properties: Properties): Part
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

function MockWorld._addInstanceToWorld(self: MockWorld, instance: Instance): ()
    instance.Parent = self._world
end

function MockWorld._spawnInstance(self: MockWorld, className: string, properties: Properties?): Instance
    local instance: Instance = Instance.new(className)
    
    if properties then
        setInstanceProperties(instance, properties)
    end
    
    self:_addInstanceToWorld(instance)
    return instance
end


return MockWorld

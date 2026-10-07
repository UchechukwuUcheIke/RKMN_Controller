--!strict
local DebugWorldVisualizer = {}
DebugWorldVisualizer.__index = DebugWorldVisualizer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DebugFolder = script.Parent
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local RKMNController = require(RKMNControllerFolder.RKMNController)
local DiagnosticCollisionQuery = require(DebugFolder.DiagnosticCollisionQuery)
local CollisionQuerySnapshot = require(DebugFolder.Data.CollisionQuerySnapshot)
local DiagnosticCastRecord = require(RKMNControllerFolder.DiagnosticCastRecord)

type RKMNController = RKMNController.RKMNController
type DiagnosticCastRecord = DiagnosticCastRecord.DiagnosticCastRecord
type DiagnosticCollisionQuery = DiagnosticCollisionQuery.DiagnosticCollisionQuery
type CollisionQuerySnapshot = CollisionQuerySnapshot.CollisionQuerySnapshot

type DebugWorldVisualizerData = {
	GroundCheckHitbox: BoxHandleAdornment,
	WallCheckRaycast: BoxHandleAdornment,
	SweepResolutionHitbox: BoxHandleAdornment,
	_visualizationFolder: Folder,
	_isEnabled: boolean,
	_collisionQuery: DiagnosticCollisionQuery,
} 

type DebugWorldVisualizerPrototype = typeof(DebugWorldVisualizer)

export type DebugWorldVisualizer = typeof(setmetatable(
	{} :: DebugWorldVisualizerData,
	{} :: DebugWorldVisualizerPrototype
))

local function createVisualizationFolder(world: WorldRoot): Folder
	local visualizationFolder: Folder = Instance.new("Folder")
	visualizationFolder.Name = "DebugWorldVisualizerFolder"
	visualizationFolder.Parent = world

	return visualizationFolder
end

-- TODO: Ideally should be in a global utils folder somewhere
local function validateArguments(...)
	local arguments = {...}
    
    for _, argument in ipairs(arguments) do
        assert(argument ~= nil)
    end
end

local function createBoxAdornment(name: string): BoxHandleAdornment
	const hitboxTransparency = 0.5
	const zIndex = 10
	local box: BoxHandleAdornment = Instance.new("BoxHandleAdornment")
	box.Name = name
	box.Transparency = hitboxTransparency
	box.ZIndex = zIndex
	box.AlwaysOnTop = true
	box.Adornee = workspace.Terrain
	box.Visible = false

	return box
end

function DebugWorldVisualizer.new(world: WorldRoot, collisionQuery: DiagnosticCollisionQuery): DebugWorldVisualizer
	validateArguments(world, collisionQuery)

	local data = {
		_visualizationFolder = createVisualizationFolder(world),
		_collisionQuery = collisionQuery,
		_isEnabled = true,
	} :: DebugWorldVisualizerData

	local self = setmetatable(data, DebugWorldVisualizer)
	self.GroundCheckHitbox = self:_createHitboxMarker("FootCollisionHitbox")
	self.WallCheckRaycast = self:_createHitboxMarker("WallCollisionRaycast")
	self.SweepResolutionHitbox = self:_createHitboxMarker("SweepResolutionHitbox")

	return self :: DebugWorldVisualizer
end

function DebugWorldVisualizer._createHitboxMarker(self: DebugWorldVisualizer, name: string): BoxHandleAdornment
	local marker: BoxHandleAdornment = createBoxAdornment(name)
	marker.Parent = self._visualizationFolder
	return marker
end

function DebugWorldVisualizer.Enable(self: DebugWorldVisualizer): ()
	self._isEnabled = true
end

function DebugWorldVisualizer.Disable(self: DebugWorldVisualizer): ()
	self._isEnabled = false
	self._hideAllVisualizations(self)
end

function DebugWorldVisualizer.IsEnabled(self: DebugWorldVisualizer): boolean
	return self._isEnabled
end

function DebugWorldVisualizer._hideAllVisualizations(self: DebugWorldVisualizer): ()
	self.GroundCheckHitbox.Visible = false
	self.WallCheckRaycast.Visible = false
	self.SweepResolutionHitbox.Visible = false
end

local function renderCastRecord(hitbox: BoxHandleAdornment, castRecord: DiagnosticCastRecord)
	hitbox.Visible = true
	hitbox.Size = castRecord.CastVolume.Size
	hitbox.CFrame = castRecord.CastVolume.CFrame

	if castRecord.Success then
		hitbox.Color3 = BrickColor.Green().Color
	else
		hitbox.Color3 = BrickColor.Red().Color
	end
end

function DebugWorldVisualizer.Render(self: DebugWorldVisualizer): ()
	self:_hideAllVisualizations()

	local snapshot: CollisionQuerySnapshot = self._collisionQuery.Snapshot
	if snapshot.GroundContactCheck then
		renderCastRecord(self.GroundCheckHitbox, snapshot.GroundContactCheck)
	end

	if snapshot.WallContactCheck then
		renderCastRecord(self.WallCheckRaycast, snapshot.WallContactCheck)
	end

	if snapshot.SweepResolution then
		renderCastRecord(self.SweepResolutionHitbox, snapshot.SweepResolution.CastRecord)
	end
end

function DebugWorldVisualizer.Destroy(self: DebugWorldVisualizer)
	self._visualizationFolder:Destroy()
	setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(DebugWorldVisualizer)

return DebugWorldVisualizer
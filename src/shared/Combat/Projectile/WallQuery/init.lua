--!strict
local CollectionService = game:GetService("CollectionService")

local WallQuery = {}
WallQuery.__index = WallQuery

WallQuery.Tag = "ProjectileWall"

const WALL_CLEARANCE = 0.05

type WallQueryData = {
	_world: WorldRoot,
	_params: RaycastParams,
	_isFilterStale: boolean,
	_connections: { RBXScriptConnection },
}

type WallQueryPrototype = typeof(WallQuery)

export type WallQuery = typeof(setmetatable(
	{} :: WallQueryData,
	{} :: WallQueryPrototype
))

local function createRaycastParams()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.RespectCanCollide = true

	return params
end

function WallQuery.new(world: WorldRoot): WallQuery
	local data: WallQueryData = {
		_world = world,
		_params = createRaycastParams(),
		_isFilterStale = true,
		_connections = {},
	}
	local self = setmetatable(data, WallQuery)

	self:_populateConnections()
	return self
end



function WallQuery._populateConnections(self: WallQuery): ()
	local function markStale()
		self:_markStale()
	end

	local instanceAddedConnection = CollectionService:GetInstanceAddedSignal(WallQuery.Tag):Connect(markStale)
	table.insert(self._connections, instanceAddedConnection)

	local instanceRemovedConnection = CollectionService:GetInstanceRemovedSignal(WallQuery.Tag):Connect(markStale)
	table.insert(self._connections, instanceRemovedConnection)
end

function WallQuery._markStale(self: WallQuery): ()
	self._isFilterStale = true
end

function WallQuery._refreshFilter(self: WallQuery): ()
	if not self._isFilterStale then
		return
	end

	self._params.FilterDescendantsInstances = CollectionService:GetTagged(WallQuery.Tag)
	self._isFilterStale = false
end


function WallQuery.FindFractionToWall(self: WallQuery, from: Vector2, to: Vector2): number?
	local rayVector = to - from
	local length = rayVector.Magnitude
	if length == 0 then
		return nil
	end

	self:_refreshFilter()
	local result = self._world:Raycast(
		Vector3.new(from.X, from.Y, 0),
		Vector3.new(rayVector.X, rayVector.Y, 0),
		self._params
	)
	if not result then
		return nil
	end

	local fractionToWall = result.Distance / length
	return fractionToWall
end

function WallQuery.FindPointBeforeWall(self: WallQuery, from: Vector2, to: Vector2): Vector2
	local fraction = self:FindFractionToWall(from, to)
	if not fraction then
		return to
	end

	local move = to - from
	local distance = math.max(0, move.Magnitude * fraction - WALL_CLEARANCE)
	return from + move.Unit * distance
end

function WallQuery.Destroy(self: WallQuery): ()
	for _, connection in self._connections do
		connection:Disconnect()
	end

	table.clear(self._connections)
	setmetatable(self :: any, nil)
	table.freeze(self)
end

table.freeze(WallQuery)

return WallQuery

--!strict
local SFXBinder = {}
SFXBinder.__index = SFXBinder
SFXBinder.ClassName = "SFXBinder"

local SFXPlayer = require(script.Parent.SFXPlayer)

type SFXPlayer = SFXPlayer.SFXPlayer

type Connection = { Disconnect: (self: any) -> () }

export type BindableSignal = {
	Connect: (self: any, handler: (...any) -> ()) -> Connection,
}

type SFXBinderData = {
	_player: SFXPlayer,
	_connections: { Connection },
}

type SFXBinderPrototype = typeof({__index = SFXBinder})

export type SFXBinder = typeof(setmetatable(
	{} :: SFXBinderData,
	{} :: SFXBinderPrototype))

function SFXBinder.new(player: SFXPlayer): SFXBinder
	local data: SFXBinderData = {
		_player = player,
		_connections = {},
	}

	return setmetatable(data, SFXBinder)
end

function SFXBinder.Bind(
	self: SFXBinder,
	signal: BindableSignal,
	sfxId: string,
	shouldPlay: ((...any) -> boolean)?): Connection

	local connection = signal:Connect(function(...)
		if shouldPlay and not shouldPlay(...) then
			return
		end

		self._player:Play(sfxId)
	end)
	table.insert(self._connections, connection)

	return connection
end

function SFXBinder._clearConnections(self: SFXBinder): ()
	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)
end

function SFXBinder.Destroy(self: SFXBinder): ()
	self:_clearConnections()
	setmetatable(self :: any, nil)
	table.freeze(self)
end

table.freeze(SFXBinder)

return SFXBinder

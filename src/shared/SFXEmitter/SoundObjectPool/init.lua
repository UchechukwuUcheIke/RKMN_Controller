--!strict
local SoundObjectPool = {}
SoundObjectPool.__index = SoundObjectPool
SoundObjectPool.ClassName = "SoundObjectPool"

const DEFAULT_PREWARM_COUNT = 1

type SoundObjectPoolData = {
	_createSound: () -> Sound,
	_available: { Sound },
	_all: { Sound },
}

type SoundObjectPoolPrototype = typeof({__index = SoundObjectPool})

export type SoundObjectPool = typeof(setmetatable(
	{} :: SoundObjectPoolData,
	{} :: SoundObjectPoolPrototype))


-- Note: Problem that my head hurts too much to fix. 
--  A sound that never fires Ended is never returned to the pool,
-- for example if its asset fails to load. The pool just grows in that case
function SoundObjectPool.new(createSound: () -> Sound, prewarmCount: number?): SoundObjectPool
	local data: SoundObjectPoolData = {
		_createSound = createSound,
		_available = {},
		_all = {},
	}
	local self = setmetatable(data, SoundObjectPool)

	for _ = 1, prewarmCount or DEFAULT_PREWARM_COUNT do
		table.insert(self._available, self:_createTracked())
	end

	return self
end

function SoundObjectPool._createTracked(self: SoundObjectPool): Sound
	local sound = self._createSound()
	table.insert(self._all, sound)
	return sound
end

function SoundObjectPool.Acquire(self: SoundObjectPool): Sound
	local sound = table.remove(self._available)
	if sound then
		return sound
	end

	return self:_createTracked()
end

function SoundObjectPool.Release(self: SoundObjectPool, sound: Sound): ()
	if table.find(self._all, sound) == nil or table.find(self._available, sound) ~= nil then
		return
	end

	table.insert(self._available, sound)
end

function SoundObjectPool.Destroy(self: SoundObjectPool): ()
	for _, sound in self._all do
		sound:Destroy()
	end
	table.clear(self._all)
	table.clear(self._available)
	setmetatable(self :: any, nil)
	table.freeze(self)
end

table.freeze(SoundObjectPool)

return SoundObjectPool

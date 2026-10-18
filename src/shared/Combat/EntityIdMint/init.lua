--!strict
local EntityIdMint = {}
EntityIdMint.__index = EntityIdMint

type EntityIdMintData = {
	_nextId: number,
}

type EntityIdMintPrototype = typeof(EntityIdMint)

export type EntityIdMint = typeof(setmetatable(
	{} :: EntityIdMintData,
	{} :: EntityIdMintPrototype
))

function EntityIdMint.new(): EntityIdMint
	local data: EntityIdMintData = {
		_nextId = 1,
	}

	return setmetatable(data, EntityIdMint)
end

-- A new entity instance id. Ids are never reused, so a late reference to a gone entity can never
-- point at a newer one. An entity uses its id for all its hurtboxes, hitboxes and weapons.
function EntityIdMint.Mint(self: EntityIdMint): number
	local id = self._nextId
	self._nextId += 1

	return id
end

return EntityIdMint

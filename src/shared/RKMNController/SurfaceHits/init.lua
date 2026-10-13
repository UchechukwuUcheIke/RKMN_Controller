local SurfaceHits = {}
SurfaceHits.__index = SurfaceHits
SurfaceHits.ClassName = "SurfaceHits"
SurfaceHits.Super = nil

type SurfaceHitsData = {
	Class: typeof(SurfaceHits),
	HitFloor: boolean,
	HitWall: boolean,
	HitCeiling: boolean,
	HitLedge: boolean,
}

type SurfaceHitsPrototype = typeof(SurfaceHits)

export type SurfaceHits = typeof(setmetatable(
	{} :: SurfaceHitsData,
	{} :: SurfaceHitsPrototype
))

function SurfaceHits.new(hitFloor: boolean?, hitWall: boolean?, hitCeiling: boolean?, hitLedge: boolean?): SurfaceHits
	local self = setmetatable({}, SurfaceHits)
	
	self.Class = SurfaceHits
	self.HitFloor = hitFloor or false
	self.HitWall = hitWall or false
	self.HitCeiling = hitCeiling or false
	self.HitLedge = hitLedge or false
	
	return self
end

function SurfaceHits.IsA(self: SurfaceHits, className: string): boolean
	local currentClass: any = self.Class
	
	while currentClass do
		if currentClass.ClassName == className then
			return true
		end
		currentClass = currentClass.Super
	end
	
	return false
end


function SurfaceHits.Destroy(self: SurfaceHits): ()
	setmetatable(self :: any, nil)
	table.freeze(self)
end

table.freeze(SurfaceHits)

return SurfaceHits
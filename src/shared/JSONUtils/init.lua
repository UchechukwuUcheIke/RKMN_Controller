--!strict
local JSONUtils = {}

export type NumberArray = { number }

const CFRAME_COMPONENT_COUNT = 12
const VECTOR3_COMPONENT_COUNT = 3

function JSONUtils.vector3ToArray(vector: Vector3): NumberArray
	return { vector.X, vector.Y, vector.Z }
end

function JSONUtils.cframeToArray(cframe: CFrame): NumberArray
	return { cframe:GetComponents() }
end

local function assertNumberArray(value: {any}, length: number, label: string): NumberArray
	local isATable = type(value) == "table"
	assert(isATable, `{label} must be an array of {length} numbers`)
	local arrayMatchesLength = #value == length
	assert(arrayMatchesLength, `{label} must have {length} numbers, got {#value}`)
	for _, component in value do
		local isANumber = type(component) == "number"
		assert(isANumber, `{label} must contain only numbers`)
	end
	return value
end

function JSONUtils.arrayToVector3(value: any, label: string): Vector3
	local array = assertNumberArray(value, VECTOR3_COMPONENT_COUNT, label)
	return Vector3.new(array[1], array[2], array[3])
end

function JSONUtils.arrayToCFrame(value: any, label: string): CFrame
	local array = assertNumberArray(value, CFRAME_COMPONENT_COUNT, label)
	return CFrame.new(table.unpack(array))
end

-- Returns nil when the field is absent; errors when it is present but not a number.
function JSONUtils.readOptionalNumber(record: any, field: string, label: string): number?
	local value = record[field]
	if value == nil then
		return nil
	end
	local isANumber = type(value) == "number"
	assert(isANumber, `{label}: {field} must be a number`)
	return value
end

return JSONUtils

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local jest = JestGlobals.jest

local MockerUtils = {}

export type MethodMap = {[string]: typeof(jest.fn())}
export type MockResult<T> = {
    Instance: T,
    Mocks: MethodMap
}

local function collectClassMethods(source: any, mockPrototype: MethodMap)
    for key, value in pairs(source) do
        if type(value) ~= "function" or type(key) ~= "string" then
            continue
        end

        local isConstructor: boolean = (key == "new")
        local isMetamethod = string.sub(key, 1, 2) == "__"
        if isConstructor or isMetamethod then
            continue
        end

        if mockPrototype[key] == nil then
            mockPrototype[key] = jest.fn()
        end
    end
end

local function populateMethods(classBlueprint: any): MethodMap
    local mockPrototype: MethodMap = {}

    local rawIndex = rawget(classBlueprint, "__index")
    local currentClass = if type(rawIndex) == "table" then rawIndex else classBlueprint

    local visitedClasses = {}
    local isClass: boolean = type(currentClass) == "table"
    local isVisitedClass: boolean? = visitedClasses[currentClass]
    while isClass and not isVisitedClass do
        visitedClasses[currentClass] = true
        collectClassMethods(currentClass, mockPrototype)

        local metatable = getmetatable(currentClass)
        if type(metatable) ~= "table" then
            break
        end

        local parentIndex = rawget(metatable, "__index")
        currentClass = if type(parentIndex) == "table" then parentIndex else nil
    end

    return mockPrototype
end

local function createMockInstance<T>(dataTable: any, prototype: MethodMap): T
    local mockInstance = setmetatable(dataTable, {
        __index = prototype
    })
    return mockInstance
end

function MockerUtils.createMockClass<T>(classBlueprint: any, mockData: {}?): MockResult<T>
    local dataTable = mockData or {}
    local mockPrototype: MethodMap = populateMethods(classBlueprint)
    local mockInstance: T = createMockInstance(dataTable, mockPrototype)

    local mockResult: MockResult<T> = {
        Instance = (mockInstance :: any) :: T,
        Mocks = mockPrototype
    }
    return mockResult
end

return MockerUtils

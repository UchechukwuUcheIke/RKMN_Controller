local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local jest = JestGlobals.jest

local MockerUtils = {}

export type MethodMap = {[string]: (...any) -> ...any}
export type MockResult<T> = {
    Instance: T,
    Mocks: MethodMap
}

local function populateMethods(classBlueprint: any): MethodMap
    local mockPrototype: MethodMap = {}
    
    local template = classBlueprint.__index or classBlueprint
    
    for key, originalFunc in pairs(template) do
        local isClassMethod: boolean = type(originalFunc) == "function"
        local isConstructor: boolean = key == "new"
        
        if not isClassMethod or isConstructor then
            continue
        end
        
        mockPrototype[key] = jest.fn()
    end

    return mockPrototype
end

local function createMockInstance(dataTable: any, prototype: MethodMap) 
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

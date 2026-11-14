--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local ExclusiveScreenMediator = require(ReplicatedStorage.ExclusiveScreenMediator)

local function makeFakeScreen()
	local screen = { IsOpenChanged = Signal.new(), isOpen = false, isOpenAllowed = true }
	function screen:IsOpen()
		return self.isOpen
	end
	function screen:SetOpenAllowed(isAllowed)
		self.isOpenAllowed = isAllowed
	end
	function screen:SetOpen(isOpen)
		self.isOpen = isOpen
		self.IsOpenChanged:Fire(isOpen)
	end
	return screen
end

local function makeFakeEntryPoint()
	local entryPoint = { isVisible = true }
	function entryPoint:SetEntryVisible(isVisible)
		self.isVisible = isVisible
	end
	return entryPoint
end

describe("ExclusiveScreenMediator", function()
	it("hides every entry point and blocks every screen while one screen is open", function()
		local mediator = ExclusiveScreenMediator.new()
		local first, second = makeFakeScreen(), makeFakeScreen()
		local entryA, entryB = makeFakeEntryPoint(), makeFakeEntryPoint()
		mediator:AddScreen(first)
		mediator:AddScreen(second)
		mediator:AddEntryPoint(entryA)
		mediator:AddEntryPoint(entryB)

		first:SetOpen(true)

		expect(entryA.isVisible).toBe(false)
		expect(entryB.isVisible).toBe(false)
		expect(first.isOpenAllowed).toBe(false)
		expect(second.isOpenAllowed).toBe(false)
	end)

	it("restores everything when the open screen closes", function()
		local mediator = ExclusiveScreenMediator.new()
		local screen = makeFakeScreen()
		local entry = makeFakeEntryPoint()
		mediator:AddScreen(screen)
		mediator:AddEntryPoint(entry)

		screen:SetOpen(true)
		screen:SetOpen(false)

		expect(entry.isVisible).toBe(true)
		expect(screen.isOpenAllowed).toBe(true)
	end)

	it("keeps entry points hidden while a second screen is still open", function()
		local mediator = ExclusiveScreenMediator.new()
		local first, second = makeFakeScreen(), makeFakeScreen()
		local entry = makeFakeEntryPoint()
		mediator:AddScreen(first)
		mediator:AddScreen(second)
		mediator:AddEntryPoint(entry)

		first:SetOpen(true)
		second:SetOpen(true)
		first:SetOpen(false)

		expect(entry.isVisible).toBe(false)
	end)

	it("hides an entry point added while a screen is already open", function()
		local mediator = ExclusiveScreenMediator.new()
		local screen = makeFakeScreen()
		mediator:AddScreen(screen)
		screen:SetOpen(true)

		local lateEntry = makeFakeEntryPoint()
		mediator:AddEntryPoint(lateEntry)

		expect(lateEntry.isVisible).toBe(false)
	end)

	it("stops reacting once destroyed", function()
		local mediator = ExclusiveScreenMediator.new()
		local screen = makeFakeScreen()
		local entry = makeFakeEntryPoint()
		mediator:AddScreen(screen)
		mediator:AddEntryPoint(entry)

		mediator:Destroy()
		screen:SetOpen(true)

		expect(entry.isVisible).toBe(true)
	end)
end)

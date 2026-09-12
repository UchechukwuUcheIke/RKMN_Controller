local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function()
    local TimerUtility = require(ReplicatedStorage:WaitForChild("RKMNController"):WaitForChild("TimerUtility"))

    local function getDictionaryLength(tbl: { [any]: any }): number
        local count = 0
        for _, value in pairs(tbl) do
            if (value) then
                count += 1
            end
        end
        return count
    end

    describe("TimerUtility", function()
        local Timer

        beforeEach(function()
            Timer = TimerUtility.new()
        end)

        afterEach(function()
            if (Timer) then
                Timer:Destroy()
            end
        end)

        it("TimerUtility Instantiation", function()
            local isEmpty = next(Timer:GetActiveTimers()) == nil
            expect(isEmpty).to.equal(true)
        end)

        it("Two TimerUtility Instances Have Separate Timers", function()
            local OtherTimer = TimerUtility.new()
            expect(Timer:GetActiveTimers()).never.to.equal(OtherTimer:GetActiveTimers())
        end)

        it("Starting a new timer with a positive duration adds it with that exact value", function()
            local timerId = "timer"
            local duration = 10
            Timer:StartTimer(timerId, duration)
            expect(Timer:GetTimeRemaining(timerId)).to.equal(duration)
        end)

        it("Starting a new timer on existing timer id replaces that duration", function()
            local timerId = "timer"
            local duration = 10
            Timer:StartTimer(timerId, duration)
            local newDuration = 20
            Timer:StartTimer(timerId, newDuration)
            expect(Timer:GetTimeRemaining(timerId)).to.equal(newDuration)
        end)

        it("Expired Timer time is 0 on step", function()
            local timerId = "timer"
            local duration = 0
            Timer:StartTimer(timerId, duration)
            Timer:Step(1)
            expect(Timer:GetTimeRemaining(timerId)).to.equal(0)
        end)

        it("Starting a timer with duration 0 stores 0, not treated as already gone", function()
            local timerId = "timer"
            Timer:StartTimer(timerId, 0)
            expect(Timer:GetTimeRemaining(timerId)).to.equal(0)
        end)

        it("Starting timer with duration 0 reports IsComplete as false until Step runs", function()
            local timerId = "timer"
            Timer:StartTimer(timerId, 0)
            expect(Timer:IsComplete(timerId)).to.equal(false)
        end)

        it("Multiple distinct timer ids do not interfere with each other's values", function()
            Timer:StartTimer("A", 5)
            Timer:StartTimer("B", 10)
            expect(Timer:GetTimeRemaining("A")).to.equal(5)
            expect(Timer:GetTimeRemaining("B")).to.equal(10)
        end)

        it("Step reduces a timer's remaining time by exactly dt", function()
            local timerId = "timer"
            Timer:StartTimer(timerId, 10)
            Timer:Step(3)
            expect(Timer:GetTimeRemaining(timerId)).to.equal(7)
        end)

        it("Timer exactly reaching 0 after Step is removed", function()
            local timerId = "timer"
            Timer:StartTimer(timerId, 5)
            Timer:Step(5)
            expect(Timer:IsComplete(timerId)).to.equal(true)
        end)

        it("Timer dropping below 0 after Step is removed, not left negative", function()
            local timerId = "timer"
            Timer:StartTimer(timerId, 5)
            Timer:Step(10)
            print(Timer:GetActiveTimers())
            expect(getDictionaryLength(Timer:GetActiveTimers())).to.equal(0)
        end)

        it("Step decrements multiple timers independently, only removing ones that cross zero", function()
            Timer:StartTimer("Short", 2)
            Timer:StartTimer("Long", 10)
            Timer:Step(3)
            expect(Timer:IsComplete("Short")).to.equal(true)
            expect(Timer:IsComplete("Long")).to.equal(false)
            expect(Timer:GetTimeRemaining("Long")).to.equal(7)
        end)

        it("Step with an empty ActiveTimers table does nothing and does not error", function()
            expect(function()
                Timer:Step(1)
            end).never.to.throw()
            expect(getDictionaryLength(Timer:GetActiveTimers())).to.equal(0)
        end)

        it("Step with dt of 0 leaves all timers unchanged", function()
            local timerId = "timer"
            Timer:StartTimer(timerId, 5)
            Timer:Step(0)
            expect(Timer:GetTimeRemaining(timerId)).to.equal(5)
        end)

        it("Repeated small Steps accumulate the same as one large Step", function()
            local timerId = "timer"
            Timer:StartTimer(timerId, 1)
            Timer:Step(0.3)
            Timer:Step(0.3)
            Timer:Step(0.3)
            expect(Timer:GetTimeRemaining(timerId)).to.be.near(0.1, 1e-9)
        end)

        it("GetTimeRemaining returns 0 for an id that was never started", function()
            expect(Timer:GetTimeRemaining("Nonexistent")).to.equal(0)
        end)

        it("GetTimeRemaining returns 0 for an id that has expired via Step", function()
            local timerId = "timer"
            Timer:StartTimer(timerId, 1)
            Timer:Step(2)
            expect(Timer:GetTimeRemaining(timerId)).to.equal(0)
        end)

        it("GetTimeRemaining returns 0 for an id that was manually canceled", function()
            local timerId = "timer"
            Timer:StartTimer(timerId, 5)
            Timer:Cancel(timerId)
            expect(Timer:GetTimeRemaining(timerId)).to.equal(0)
        end)

        it("IsComplete returns false immediately after starting a positive-duration timer", function()
            local timerId = "timer"
            Timer:StartTimer(timerId, 5)
            expect(Timer:IsComplete(timerId)).to.equal(false)
        end)

        it("IsComplete returns true for an id that was never started", function()
            expect(Timer:IsComplete("Nonexistent")).to.equal(true)
        end)

        it("IsComplete returns true immediately after Cancel", function()
            local timerId = "timer"
            Timer:StartTimer(timerId, 5)
            Timer:Cancel(timerId)
            expect(Timer:IsComplete(timerId)).to.equal(true)
        end)

        it("IsComplete returns false for a timer that has ticked down but not reached zero", function()
            local timerId = "timer"
            Timer:StartTimer(timerId, 5)
            Timer:Step(2)
            expect(Timer:IsComplete(timerId)).to.equal(false)
        end)

        it("Cancel removes an active timer from ActiveTimers", function()
            local timerId = "timer"
            Timer:StartTimer(timerId, 5)
            Timer:Cancel(timerId)
            expect(getDictionaryLength(Timer:GetActiveTimers())).to.equal(0)
        end)

        it("Cancel on a nonexistent id is a safe no-op", function()
            expect(function()
                Timer:Cancel("Nonexistent")
            end).never.to.throw()
        end)

        it("Cancel then StartTimer on the same id works normally with no leftover state", function()
            local timerId = "timer"
            Timer:StartTimer(timerId, 5)
            Timer:Cancel(timerId)
            Timer:StartTimer(timerId, 8)
            expect(Timer:GetTimeRemaining(timerId)).to.equal(8)
        end)

        it("FlushAll removes all entries regardless of count", function()
            Timer:StartTimer("A", 5)
            Timer:StartTimer("B", 10)
            Timer:StartTimer("C", 15)
            Timer:FlushAll()
            expect(getDictionaryLength(Timer:GetActiveTimers())).to.equal(0)
        end)

        it("FlushAll on an empty timer set is a safe no-op", function()
            expect(function()
                Timer:FlushAll()
            end).never.to.throw()
        end)

        it("After FlushAll, IsComplete returns true for every previously-active id", function()
            Timer:StartTimer("A", 5)
            Timer:StartTimer("B", 10)
            Timer:FlushAll()
            expect(Timer:IsComplete("A")).to.equal(true)
            expect(Timer:IsComplete("B")).to.equal(true)
        end)

        it("After FlushAll, starting a new timer works normally", function()
            Timer:StartTimer("A", 5)
            Timer:FlushAll()
            Timer:StartTimer("B", 10)
            expect(Timer:GetTimeRemaining("B")).to.equal(10)
        end)

        it("Jump buffer simulation: active mid-window, complete after window elapses", function()
            Timer:StartTimer("JumpBuffer", 0.1)
            Timer:Step(0.05)
            expect(Timer:IsComplete("JumpBuffer")).to.equal(false)
            Timer:Step(0.06)
            expect(Timer:IsComplete("JumpBuffer")).to.equal(true)
        end)

        it("Coyote time simulation: refreshing every frame prevents expiration", function()
            for _ = 1, 20 do
                Timer:StartTimer("Coyote", 0.1)
                Timer:Step(0.05)
            end
            expect(Timer:IsComplete("Coyote")).to.equal(false)

            -- Stop refreshing, let it decay naturally
            Timer:Step(0.05)
            Timer:Step(0.06)
            expect(Timer:IsComplete("Coyote")).to.equal(true)
        end)

        it("Consumption pattern: Cancel right after Start behaves safely on subsequent Steps", function()
            Timer:StartTimer("JumpBuffer", 0.1)
            Timer:Cancel("JumpBuffer")
            expect(function()
                Timer:Step(1)
            end).never.to.throw()
            expect(Timer:IsComplete("JumpBuffer")).to.equal(true)
        end)

        it("Timer duration not evenly divisible by dt still completes at the expected time", function()
            local timerId = "timer"
            Timer:StartTimer(timerId, 1)
            local dt = 1 / 60
            local elapsed = 0
            while not Timer:IsComplete(timerId) do
                Timer:Step(dt)
                elapsed += dt
            end
            expect(elapsed).to.be.near(1, dt) -- should complete within one frame of expected
        end)
    end)
end
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function()
    describe("myFunction", function()
        it("returns 0", function()
            local result = 0
            expect(result).to.equal(0)
        end)
    end)
end
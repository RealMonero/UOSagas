local lastSkinnedSerial = -1
while true do
    local knife = Items.FindByType(0xFEA9) -- Knife type
    if knife then
        local filter = { onground=true, rangemax=1, graphics={0x2006, 0x2007, 0x2008} } -- Corpses within 1 tile
        local corpses = Items.FindByFilter(filter)
        if corpses and #corpses > 0 then
            local corpse = corpses[1]
            if corpse.Serial ~= lastSkinnedSerial and corpse.Distance <= 2 then
                Pause(1500)
                Player.UseObject(knife.Serial)
                if Targeting.WaitForTarget(2000) then
                    Targeting.Target(corpse.Serial)
                end
                lastSkinnedSerial = corpse.Serial
                Pause(1250)
                if Items.FindBySerial(corpse.Serial) then
                    local lootFilter = { RootContainer = corpse.Serial } -- No graphics filter to loot all items
                    local items = Items.FindByFilter(lootFilter)
                    if not items or #items == 0 then
                        Pause(1000)
                        items = Items.FindByFilter(lootFilter)
                    end
                    if items then
                        for _, item in ipairs(items) do
                            if item.RootContainer ~= Player.Serial and (item.X ~= Player.X or item.Y ~= Player.Y) then
                                Player.PickUp(item.Serial, 1000)
                                Pause(200)
                                Player.DropInBackpack()
                                Pause(500)
                            end
                        end
                    end
                    local scissors = Items.FindByType(0x0F9F) -- Scissors type
                    if scissors then
                        local hideFilter = { RootContainer = Player.Serial, graphics = {0x1078, 0x1079} } -- Hides
                        local hides = Items.FindByFilter(hideFilter)
                        if hides then
                            for _, hide in ipairs(hides) do
                                Player.UseObject(scissors.Serial)
                                if Targeting.WaitForTarget(2000) then
                                    Targeting.Target(hide.Serial)
                                end
                                Pause(1200)
                            end
                        end
                    end
                end
            end
        end
    end
    Pause(500)
end

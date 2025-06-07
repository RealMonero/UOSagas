--[[
    Title: Ultima Online Fishing Macro
    Version: 1.0.1
    Last Updated: June 7, 2025
    Description: Automates fishing in Ultima Online by using an equipped fishing pole (Graphic ID 0x0DC0)
                 and targeting the last selected water tile. Equips a new pole from inventory if needed
                 and handles pole breaks. When fish are not biting, moves the boat forward for 5 seconds.
                 Provides overhead messages (visible only to the player) for feedback.
    Usage:
        - Place fishing poles (Graphic ID 0x0DC0) in your inventory.
        - Run the script in a UO client (e.g., Razor, UOSteam) while on a boat.
        - Select a water tile when prompted.
        - The script will fish continuously, equipping new poles and moving the boat when needed.
    Requirements: UO client with support for Items.FindByLayer, Items.FindByFilter, Player.Equip,
                  Player.UseObject, Player.Say, Targeting.WaitForTarget, Targeting.TargetLast,
                  Journal.Contains, Journal.Clear, and Messages.Overhead.
    Notes:
        - Adjust FISHING_DELAY for server-specific timing (e.g., 7000-10000 ms).
        - Manual water targeting required initially; automation can be added.
        - Boat movement uses "forward" and "stop" commands; ensure you're on a boat.
        - Share issues or contributions on GitHub.
--]]

-- Configuration
local FISHING_POLE_ID = 0x0DC0      -- Graphic ID for fishing poles
local FISHING_DELAY = 8000          -- Delay (ms) for fishing action (adjust as needed)
local TARGET_TIMEOUT = 1000         -- Timeout (ms) for targeting water
local EQUIP_DELAY = 1000            -- Delay (ms) for equipping pole
local BOAT_MOVE_DELAY = 5000        -- Delay (ms) for boat movement when no fish are biting
local MESSAGE_HUE = 69              -- Hue for overhead messages (orange)

-- Function: GetEquippedFishingPole
-- Purpose: Checks if a fishing pole is equipped in either hand (layers 1 or 2).
-- Returns: Equipped fishing pole item or nil if none found.
function GetEquippedFishingPole()
    local pole = nil
    -- Check primary hand (layer 1)
    local checkPole = Items.FindByLayer(1)
    if checkPole then
        local name = string.lower(checkPole.Name or "")
        if string.find(name, "fishing pole") then
            pole = checkPole
        end
    end
    -- Check secondary hand (layer 2) if no pole found
    if not pole then
        checkPole = Items.FindByLayer(2)
        if checkPole then
            local name = string.lower(checkPole.Name or "")
            if string.find(name, "fishing pole") then
                pole = checkPole
            end
        end
    end
    return pole
end

-- Function: EquipFishingPole
-- Purpose: Finds and equips a fishing pole from the player's inventory.
-- Returns: Equipped fishing pole item or nil if none found/equipped.
function EquipFishingPole()
    -- Search inventory for fishing poles
    local items = Items.FindByFilter({ RootContainer = Player.Serial })
    local equipPole = nil
    if items then
        for i = 1, #items do
            local item = items[i]
            local name = string.lower(item.Name or "")
            if string.find(name, "fishing pole") then
                equipPole = item
                break
            end
        end
    end
    if equipPole then
        Player.Equip(equipPole.Serial)  -- Equip the pole
        Pause(EQUIP_DELAY)              -- Wait for equip to process
        return GetEquippedFishingPole() -- Verify equip success
    end
    return nil
end

-- Function: CheckFishingStatus
-- Purpose: Checks journal for fishing failure messages (e.g., pole breaks, no fish).
-- Returns: True if a failure is detected, false otherwise.
function CheckFishingStatus()
    local failureMessages = {
        "your fishing pole breaks",     -- Pole has broken
        "you fail to catch anything",   -- No fish in the area
        "that is too far away",         -- Target out of range
        "you cannot see that"           -- Target not visible
    }
    for _, msg in ipairs(failureMessages) do
        if Journal.Contains(msg) then
            return true
        end
    end
    return false
end

-- Function: Main
-- Purpose: Main loop for fishing, handling pole equipping, water targeting, and boat movement.
function Main()
    Journal.Clear()                 -- Clear journal for fresh error detection
    local needNewTarget = true      -- Flag for manual water targeting

    while true do
        -- Check for equipped fishing pole
        local fishingPole = GetEquippedFishingPole()
        if not fishingPole then
            fishingPole = EquipFishingPole()
            if not fishingPole then
                Messages.Overhead("No fishing pole found!", MESSAGE_HUE, Player.Serial)
                return  -- Stop if no pole is available
            end
            Messages.Overhead("Equipped new fishing pole.", MESSAGE_HUE, Player.Serial)
        end

        -- Use fishing pole
        Player.UseObject(fishingPole.Serial)
        if Targeting.WaitForTarget(TARGET_TIMEOUT) then
            if needNewTarget then
                Messages.Overhead("Select water to fish!", MESSAGE_HUE, Player.Serial)
                needNewTarget = false   -- Switch to auto-targeting
                Pause(2000)             -- Time for manual targeting
            else
                Targeting.TargetLast()  -- Auto-target last water tile
            end
        else
            Messages.Overhead("Failed to target water!", MESSAGE_HUE, Player.Serial)
            needNewTarget = true        -- Prompt for new target
            Pause(1000)
            goto continue
        end

        -- Wait for fishing action
        Pause(FISHING_DELAY)

        -- Check journal for failure conditions (e.g., pole breaks or no fish)
        if CheckFishingStatus() then
            if Journal.Contains("your fishing pole breaks") then
                Messages.Overhead("Fishing pole broke!", MESSAGE_HUE, Player.Serial)
                Journal.Clear()
                fishingPole = EquipFishingPole()
                if not fishingPole then
                    Messages.Overhead("No fishing pole found!", MESSAGE_HUE, Player.Serial)
                    return  -- Stop if no pole is available
                end
                Messages.Overhead("Equipped new fishing pole.", MESSAGE_HUE, Player.Serial)
                needNewTarget = true -- Prompt for new target after equipping new pole
            elseif Journal.Contains("you fail to catch anything") then
                Messages.Overhead("No fish here, moving boat!", MESSAGE_HUE, Player.Serial)
                Player.Say("forward")    -- Say "forward" to move the boat
                Pause(BOAT_MOVE_DELAY)  -- Wait 5 seconds for boat to move
                Player.Say("stop")      -- Say "stop" to halt the boat
                needNewTarget = true    -- Prompt for new water target
                Journal.Clear()
            else
                Messages.Overhead("Fishing error, Retry!", MESSAGE_HUE, Player.Serial)
                Journal.Clear()
            end
        end

        ::continue::
    end
end

-- Execute the script
Main()

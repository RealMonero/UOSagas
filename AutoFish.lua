--[[
    Title: Ultima Online Fishing Macro
    Version: 1.0.0
    Last Updated: June 7, 2025
    Description: A fishing macro for Ultima Online that automates fishing by using an equipped fishing pole
                 (Graphic ID 0x0DC0) and targeting the last selected water tile. Automatically equips a new pole
                 from inventory if none is equipped or if the current pole breaks. Provides overhead messages
                 (visible only to the player) for feedback on errors or actions.
    Usage: 
        - Ensure fishing poles (Graphic ID 0x0DC0) are in your inventory or equipped.
        - Run the script and manually select a water tile when prompted.
        - The script will continuously fish at the selected spot, equipping new poles as needed.
    Requirements: Compatible with UO clients like Razor or UOSteam that support Items.FindByLayer,
                  Items.FindByFilter, Player.Equip, Player.UseObject, Targeting.WaitForTarget,
                  Targeting.TargetLast, Journal.Contains, Journal.Clear, and Messages.Overhead.
    Notes: Adjust FISHING_DELAY if your server has different fishing mechanics (e.g., 7-10 seconds).
           Manual water targeting is required initially; automation of water tile detection can be added.
--]]

-- Configuration
local FISHING_POLE_ID = 0x0DC0      -- Graphic ID for fishing poles in Ultima Online
local FISHING_DELAY = 8000          -- Delay (ms) for fishing action completion (adjust based on server mechanics)
local TARGET_TIMEOUT = 1000         -- Timeout (ms) for waiting to target a water tile
local EQUIP_DELAY = 1000            -- Delay (ms) to allow equipping a fishing pole
local MESSAGE_HUE = 69              -- Hue for overhead messages (69 = orange, visible only to player)

-- Function: GetEquippedFishingPole
-- Purpose: Checks if a fishing pole is equipped in either hand (layers 1 or 2).
-- Returns: The equipped fishing pole item object or nil if none found.
function GetEquippedFishingPole()
    local pole = nil
    -- Check layer 1 (primary hand)
    local checkPole = Items.FindByLayer(1)
    if checkPole then
        local name = string.lower(checkPole.Name or "")
        if string.find(name, "fishing pole") then
            pole = checkPole
        end
    end
    -- If no pole in layer 1, check layer 2 (secondary hand)
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
-- Purpose: Finds a fishing pole in the player's inventory and equips it.
-- Returns: The equipped fishing pole item object or nil if none found or equip fails.
function EquipFishingPole()
    -- Search inventory for a fishing pole
    local items = Items.FindByFilter({ RootContainer = Player.Serial })
    local equipPole = nil
    if items then
        -- Iterate through inventory items to find a fishing pole by name
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
        -- Equip the found pole using Player.Equip
        Player.Equip(equipPole.Serial)
        Pause(EQUIP_DELAY) -- Wait for the equip action to complete
        return GetEquippedFishingPole() -- Verify the pole is equipped
    end
    return nil
end

-- Function: CheckFishingStatus
-- Purpose: Checks the journal for messages indicating fishing failure (e.g., pole breaks or no fish).
-- Returns: True if a failure condition is detected, false otherwise.
function CheckFishingStatus()
    local failureMessages = {
        "your fishing pole breaks",       -- Pole has broken
        "you fail to catch anything",     -- No fish in the area
        "that is too far away",           -- Target is out of range
        "you cannot see that"             -- Target is not visible
    }
    for _, msg in ipairs(failureMessages) do
        if Journal.Contains(msg) then
            return true
        end
    end
    return false
end

-- Function: Main
-- Purpose: Main fishing loop that handles pole equipping, targeting water, and continuous fishing.
function Main()
    -- Clear journal to start with a clean slate
    Journal.Clear()
    local needNewTarget = true -- Flag to prompt for manual water targeting on first run or after failure

    -- Main loop to keep fishing until stopped
    while true do
        -- Check for an equipped fishing pole
        local fishingPole = GetEquippedFishingPole()
        if not fishingPole then
            -- No pole equipped; attempt to equip one from inventory
            fishingPole = EquipFishingPole()
            if not fishingPole then
                Messages.Overhead("No fishing pole found!", MESSAGE_HUE, Player.Serial)
                return -- Stop script if no pole is available
            end
            Messages.Overhead("Equipped new fishing pole.", MESSAGE_HUE, Player.Serial)
        end

        -- Use the fishing pole
        Player.UseObject(fishingPole.Serial)
        if Targeting.WaitForTarget(TARGET_TIMEOUT) then
            if needNewTarget then
                -- Prompt player to manually select a water tile
                Messages.Overhead("Select water to fish!", MESSAGE_HUE, Player.Serial)
                needNewTarget = false -- Switch to auto-targeting after manual selection
                Pause(2000) -- Allow time for player to select water
            else
                -- Auto-target the last selected water tile
                Targeting.TargetLast()
            end
        else
            -- Targeting failed (e.g., no valid target or timeout)
            Messages.Overhead("Failed to target water!", MESSAGE_HUE, Player.Serial)
            needNewTarget = true -- Prompt for new manual target on next attempt
            Pause(1000) -- Brief pause to avoid spamming
            goto continue
        end

        -- Wait for the fishing action to complete
        Pause(FISHING_DELAY)

        -- Check journal for failure conditions (e.g., pole breaks or no fish)
        if CheckFishingStatus() then
            if Journal.Contains("your fishing pole breaks") then
                Messages.Overhead("Fishing pole broke!", MESSAGE_HUE, Player.Serial)
                Journal.Clear()
                fishingPole = EquipFishingPole()
                if not fishingPole then
                    Messages.Overhead("No fishing pole found!", MESSAGE_HUE, Player.Serial)
                    return -- Stop script if no pole is available
                end
                Messages.Overhead("Equipped new fishing pole.", MESSAGE_HUE, Player.Serial)
                needNewTarget = true -- Prompt for new target after equipping new pole
            elseif Journal.Contains("you fail to catch anything") then
                Messages.Overhead("No fish here, try another spot!", MESSAGE_HUE, Player.Serial)
                needNewTarget = true -- Prompt for new target
                Journal.Clear()
            else
                Messages.Overhead("Fishing error, retrying...", MESSAGE_HUE, Player.Serial)
                Journal.Clear()
            end
        end

        ::continue::
    end
end

-- Start the script
Main()

--[[
  Title: Ultima Online Lockpicking Training Script (Paragon Chest)
  Version: 1.0.3
  Last Updated: June 7, 2025
  Description: Automates lockpicking a paragon chest in UO Sagas using a lockpick (Graphic ID 0x14FD) and the
               custom lockpicking gump (ID 313384064). Closes the gump at each attempt, finds a lockpick and
               paragon chest (facing right: copper/bronze/iron, facing left: shadow), checks player HP against a
               threshold, and interacts with the gump (button 2) to attempt lockpicking. Continues until no lockpicks
               remain. Provides feedback via chat and printed messages.
  Usage:
    - Place lockpicks (Graphic ID 0x14FD) in your inventory.
    - Stand near a paragon chest (Graphic IDs 0x9FF8 or 0x9FF9).
    - Ensure HP is above the threshold (default 75) to avoid damage from failures.
    - Run the script in a UO Sagas client (Razor Enhanced variant).
    - The script will lockpick the chest until lockpicks are depleted.
  Notes:
    - CHEST_IDS (0x9FF8 for copper/bronze/iron, 0x9FF9 for shadow) are verified for UO Sagas paragon chests.
    - 0–50 skill: Iron (0x9FF8); 50–80 skill: Shadow (0x9FF9); adjust CHEST_IDS for skill level.
    - Gump ID (313384064), button 0 (close), and button 2 (lockpick) are verified.
    - HP_THRESHOLD (default 75) prevents attempts if HP is too low; adjust based on risk.
    - Timing (1000ms for gump waits and targeting) matches confirmed sequence; adjust if needed.
    - No key or relocking required; server handles lock reset.
    - Share issues or contributions on GitHub.
--]]

-- Configuration
local LOCKPICK_ID = 0x14FD      -- Graphic ID for lockpicks (verified for UO Sagas)
local CHEST_IDS = {0x9FF8, 0x9FF9} -- Graphic IDs: 0x9FF8 (copper/bronze/iron, right-facing), 0x9FF9 (shadow, left-facing)
local GUMP_ID = 313384064      -- Gump ID for UO Sagas lockpicking (verified)
local GUMP_CLOSE_BUTTON = 0    -- Button ID to close gump (e.g., "Cancel")
local GUMP_LOCKPICK_BUTTON = 2 -- Button ID to attempt lockpicking (verified)
local HP_THRESHOLD = 75        -- Minimum HP to attempt lockpicking; adjust based on trap damage risk
local HP_CHECK_PAUSE = 5000    -- Pause (ms) when HP is below threshold; allows regen or healing
local TARGET_TIMEOUT = 1000    -- Timeout (ms) for targeting chest; increase if targeting fails
local GUMP_TIMEOUT = 1000      -- Timeout (ms) for gump waits; increase if gump is slow
local PAUSE_AFTER_GUMP = 1000  -- Pause (ms) after gump interaction for server processing

-- Function: FindParagonChest
-- Purpose: Searches for a paragon chest using multiple Graphic IDs (e.g., 0x9FF8, 0x9FF9).
-- Returns: Chest item or nil if none found.
function FindParagonChest()
    for _, graphic_id in ipairs(CHEST_IDS) do
        local chest = Items.FindByType(graphic_id)
        if chest then
            return chest -- Return first chest found
        end
    end
    return nil -- No chest found
end

-- Main loop: Continues until no lockpicks remain or an error breaks the loop
while true do
    -- Close gump if open to ensure fresh attempt
    -- Button 0 typically cancels or closes the gump
    Gumps.PressButton(GUMP_ID, GUMP_CLOSE_BUTTON)
    Pause(500) -- Brief pause to ensure gump closes before proceeding

    -- Check player HP before attempting lockpicking
    -- Failures may trigger traps, causing damage
    if Player.Hits < HP_THRESHOLD then
        Messages.Print("HP too low (" .. Player.Hits .. "/" .. Player.MaxHits .. "); waiting to recover")
        Player.Say("Low HP, waiting") -- Notify player via chat
        Pause(HP_CHECK_PAUSE) -- Wait for regen or manual healing
        goto continue -- Skip to next loop iteration
    end

    -- Find lockpick in player’s inventory
    local lp = Items.FindByType(LOCKPICK_ID)
    if not lp then
        Player.Say("No lockpick") -- Notify player via chat
        break -- Exit loop if no lockpicks found
    end

    -- Find paragon chest in range
    -- Supports both facing directions (right: 0x9FF8, left: 0x9FF9)
    local chest = FindParagonChest()
    if not chest then
        Player.Say("No paragon chest") -- Notify player via chat
        break -- Exit loop if no chest found
    end

    -- Log chest details for debugging
    -- Helps confirm correct Graphic ID and serial
    Messages.Print("Picking paragon chest: " .. chest.Serial .. " (Graphic ID: " .. string.format("0x%04X", chest.Graphic) .. ")")

    -- Use lockpick and target chest
    Player.UseObject(lp.Serial) -- Activate lockpick
    if Targeting.WaitForTarget(TARGET_TIMEOUT) then
        Targeting.Target(chest.Serial) -- Target the chest
    else
        Messages.Print("Failed to target chest: " .. chest.Serial) -- Log targeting failure
        Pause(1000) -- Wait before retrying to avoid spamming
        goto continue -- Skip to next loop iteration
    end

    -- Wait for lockpicking gump and interact
    -- Gump should appear after targeting the chest
    if Gumps.WaitForGump(GUMP_ID, GUMP_TIMEOUT) then
        Gumps.PressButton(GUMP_ID, GUMP_LOCKPICK_BUTTON) -- Press button 2 to attempt lockpicking
        Messages.Print("Pressed lockpick button on chest: " .. chest.Serial) -- Log button press
    else
        Messages.Print("Gump not found for chest: " .. chest.Serial) -- Log gump failure
        Pause(1000) -- Wait before retrying
        goto continue -- Skip to next loop iteration
    end

    -- Wait for gump updates (confirmed sequence)
    -- Two waits handle server responses (e.g., success/failure messages)
    if not Gumps.WaitForGump(GUMP_ID, GUMP_TIMEOUT) then
        Messages.Print("First gump update not received for chest: " .. chest.Serial) -- Log if update fails
    end
    if not Gumps.WaitForGump(GUMP_ID, GUMP_TIMEOUT) then
        Messages.Print("Second gump update not received for chest: " .. chest.Serial) -- Log if update fails
    end

    -- Pause before next attempt to allow server processing
    -- Adjust if server enforces a lockpicking cooldown
    Pause(PAUSE_AFTER_GUMP)

    ::continue:: -- Label for skipping failed attempts
end

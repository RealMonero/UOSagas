--[[
  Title: Ultima Online Lockpicking Training Script (Paragon Chest)
  Version: 1.0.0
  Last Updated: June 7, 2025
  Description: Automates lockpicking a paragon chest in UO Sagas using a lockpick (Graphic ID 0x14FD) and the
               custom lockpicking gump (ID 313384064). Closes the gump at each attempt, finds a lockpick and
               paragon chest, uses the lockpick to target the chest, and interacts with the gump (button 2) to
               attempt lockpicking. Continues until no lockpicks remain. Provides feedback via chat and printed messages.
  Usage:
    - Place lockpicks (Graphic ID 0x14FD) in your inventory.
    - Stand near a paragon chest (Graphic ID 0x0E7C or adjust as needed).
    - Run the script in a UO Sagas client
    - The script will lockpick the chest until lockpicks are depleted.
  Requirements: UO client with support for Items.FindByType, Player.UseObject, Player.Say,
                Targeting.WaitForTarget, Targeting.Target, Gumps.WaitForGump, Gumps.PressButton,
                Messages.Print, and Pause.
  Notes:
    - Adjust CHEST_ID if your paragon chest has a different Graphic ID (e.g., 0x0E7C for treasure chests).
    - Gump ID (313384064), button 0 (close), and button 2 (lockpick) are verified by working sequence.
    - Timing (1000ms for gump waits and targeting) matches confirmed sequence; adjust if needed.
    - No key or relocking required for paragon chests.
    - Share issues or contributions on GitHub.
--]]

-- Configuration
local LOCKPICK_ID = 0x14FD      -- Graphic ID for lockpicks
local CHEST_ID = 0x9FF8       -- Graphic ID for paragon chest (adjust if needed)
local GUMP_ID = 313384064      -- Gump ID for UO Sagas lockpicking
local GUMP_CLOSE_BUTTON = 0    -- Button ID to close gump
local GUMP_LOCKPICK_BUTTON = 2 -- Button ID to attempt lockpicking
local TARGET_TIMEOUT = 1000    -- Timeout (ms) for targeting
local GUMP_TIMEOUT = 1000      -- Timeout (ms) for gump waits
local PAUSE_AFTER_GUMP = 1000  -- Pause (ms) after gump interaction

-- Main loop
while true do
    -- Close gump if open
    Gumps.PressButton(GUMP_ID, GUMP_CLOSE_BUTTON)
    Pause(500) -- Brief pause to ensure gump closes

    -- Find lockpick
    local lp = Items.FindByType(LOCKPICK_ID)
    if not lp then
        Player.Say("No lockpick")
        break
    end

    -- Find paragon chest
    local chest = Items.FindByType(CHEST_ID)
    if not chest then
        Player.Say("No paragon chest")
        break
    end

    -- Use lockpick and target chest
    Messages.Print("Picking paragon chest: " .. chest.Serial)
    Player.UseObject(lp.Serial)
    if Targeting.WaitForTarget(TARGET_TIMEOUT) then
        Targeting.Target(chest.Serial)
    else
        Messages.Print("Failed to target chest: " .. chest.Serial)
        Pause(1000)
        goto continue
    end

    -- Wait for lockpicking gump and interact
    if Gumps.WaitForGump(GUMP_ID, GUMP_TIMEOUT) then
        Gumps.PressButton(GUMP_ID, GUMP_LOCKPICK_BUTTON)
        Messages.Print("Pressed lockpick button on chest: " .. chest.Serial)
    else
        Messages.Print("Gump not found for chest: " .. chest.Serial)
        Pause(1000)
        goto continue
    end

    -- Wait for gump updates (confirmed sequence)
    if not Gumps.WaitForGump(GUMP_ID, GUMP_TIMEOUT) then
        Messages.Print("First gump update not received for chest: " .. chest.Serial)
    end
    if not Gumps.WaitForGump(GUMP_ID, GUMP_TIMEOUT) then
        Messages.Print("Second gump update not received for chest: " .. chest.Serial)
    end

    -- Pause before next attempt
    Pause(PAUSE_AFTER_GUMP)

    ::continue::
end

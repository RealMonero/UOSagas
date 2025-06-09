--[[
    Script: TrainHidingStealth.lua
    Version: 1.0.0
    Date: June 8, 2025
    Description: A Lua script for training Hiding and Stealth skills in Ultima Online.
                 Repeatedly uses Hiding and Stealth skills without movement, with feedback.
    License: MIT License (or specify your preferred license)
--]]

-- Configuration settings
local hidingDelay = 250            -- Delay (in milliseconds) after using Hiding skill
local stealthDelay = 250           -- Delay (in milliseconds) after using Stealth skill
local pauseOnFailure = 500         -- Delay (in milliseconds) after a failed attempt

-- Function: attemptHide
-- Purpose: Attempts to use the Hiding skill if player is not hidden
-- Returns: True if hidden or Hiding was used
function attemptHide()
    if Player.IsHidden then
        Messages.Overhead("Already hidden", 69, Player.Serial)
        return true
    end

    Messages.Overhead("Attempting to hide...", 22, Player.Serial)
    Skills.Use("Hiding")
    Pause(hidingDelay)
    return true
end

-- Function: attemptStealth
-- Purpose: Attempts to use the Stealth skill when hidden
function attemptStealth()
    if not Player.IsHidden then
        Messages.Overhead("Not hidden, cannot stealth!", 69, Player.Serial)
        Pause(pauseOnFailure)
        return
    end

    -- Attempt to use the Stealth skill
    Messages.Overhead("Using Stealth...", 10, Player.Serial)
    Skills.Use("Stealth")
    Pause(stealthDelay)
end

-- Function: main
-- Purpose: Main loop for training Hiding and Stealth skills
function main()
    while true do
        -- Attempt to hide
        if attemptHide() and Player.IsHidden then
            -- If hidden, attempt to train Stealth
            attemptStealth()
        end
    end
end

-- Entry point: Start the script
main()

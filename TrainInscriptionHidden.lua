--[[
    Script: TrainInscriptionHidden.lua
    Version: 1.0.0
    Date: June 8, 2025
    Description: UOSagas inscription training script.
--]]

-- Configuration settings
local scribePenType = 0x0FBF       -- Graphic ID for the scribe pen used to craft scrolls
local gumpId = 2653346093          -- Gump ID for the scribe pen's crafting menu
local gumpTimeout = 3000           -- Timeout (in milliseconds) to wait for the crafting gump to load
local manaThreshold = 50           -- Minimum mana required to attempt crafting a scroll
local hidingDelay = 250            -- Delay (in milliseconds) after using Hiding or Stealth skills

-- Function: findScribePen
-- Purpose: Searches the player's backpack for a scribe pen
-- Returns: Item object if found, nil otherwise
function findScribePen()
    -- Filter items in the player's backpack for the scribe pen graphic
    local items = Items.FindByFilter({ RootContainer = Player.Serial, graphics = scribePenType })
    for _, item in ipairs(items) do
        -- Return the first scribe pen found
        if item and item.Graphic == scribePenType then
            return item
        end
    end
    -- Return nil if no scribe pen is found
    return nil
end

-- Function: main
-- Purpose: Main loop for crafting scrolls, maintaining hidden status, and providing feedback
function main()
    while true do
        -- Check if the player is hidden
        if Player.IsHidden then
            Messages.Overhead("Hidden", 69, Player.Serial) -- Display hidden status
        else
            -- Attempt to hide if not hidden
            Messages.Overhead("Player is not hidden", 22, Player.Serial)
            Skills.Use("Hiding")
            Pause(hidingDelay)
        end

        -- Check if player has enough mana to craft
        if Player.Mana < manaThreshold then
            Messages.Overhead("Low mana, waiting for regen...", 69, Player.Serial)
            Pause(500) -- Wait for mana regeneration
        else
            -- Attempt to find a scribe pen in the backpack
            local scribePen = findScribePen()
            if not scribePen then
                Messages.Overhead("No scribe pen found in backpack!", 69, Player.Serial)
                Pause(500) -- Pause to prevent spamming
            else
                -- Use the scribe pen to open the crafting gump
                Player.UseObject(scribePen.Serial)
                if Gumps.WaitForGump(gumpId, gumpTimeout) then
                    -- Navigate to the scroll in the crafting gump
                    Gumps.PressButton(gumpId, 21)
                    if Gumps.WaitForGump(gumpId, gumpTimeout) then
                        -- Attempt to craft the scroll
                        Gumps.PressButton(gumpId, 0)
                        Messages.Overhead("Crafting...", 10, Player.Serial)
                    else
                        -- Handle failure to navigate the gump
                        Messages.Overhead("Failed to craft scroll!", 69, Player.Serial)
                        Pause(500)
                    end
                else
                    -- Handle failure to open the crafting gump
                    Messages.Overhead("Failed to open crafting gump!", 69, Player.Serial)
                    Pause(500)
                end
            end
        end
    end
end

-- Entry point: Start the script
main()

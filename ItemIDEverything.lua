-- ItemIdentifier.lua
-- Version: 1.0.0
-- Description: A script for Ultima Online to automatically identify items in a nearby container
--              using the Item Identification skill. Searches for one container (pouch, backpack,
--              bag, wooden box, or paragon chest) on the same tile as the player and identifies
--              all non-container items inside it.  Change the rangemax as needed.  I drop all my
--              itmems into a pouch and stand on top of it.

-- Configuration
-- Define graphic IDs for different container types to search for and exclude
local CONTAINER_GRAPHICS = {
    Pouch = 0x0E79,           -- Graphic ID for pouch
    Backpack = 0x0E75,        -- Graphic ID for backpack
    Bag = 0x0E76,             -- Graphic ID for bag
    WoodenBox = 0x0E7D,       -- Graphic ID for wooden box
    ParagonChestLeft = 0x9FF9, -- Graphic ID for paragon chest (facing left)
    ParagonChestRight = 0x9FF8 -- Graphic ID for paragon chest (facing right)
}
local ITEM_ID_DELAY = 900     -- Delay (ms) after using Item Identification skill
local LOOP_DELAY = 100        -- Delay (ms) between main loop iterations
local GUMP_WAIT_TIMEOUT = 3000 -- Timeout (ms) for waiting for targeting cursor

-- Function to find a single container on the same tile as the player
-- Searches for any one of the specified container types
function GetContainer()
    -- Create a filter to find containers on the ground at range 0 (same tile)
    local filter = {
        onground = true,      -- Must be on the ground
        rangemax = 0,         -- Must be on the same tile as the player
        graphics = {},        -- Will be populated with container graphic IDs
        container = true      -- Must be a container
    }
    
    -- Populate filter.graphics with all container graphic IDs
    for _, graphic in pairs(CONTAINER_GRAPHICS) do
        table.insert(filter.graphics, graphic)
    end
    
    -- Find containers matching the filter
    local containers = Items.FindByFilter(filter)
    
    -- Check if no containers were found
    if not containers or #containers == 0 then
        Messages.Overhead("No container found with graphics: " .. table.concat(filter.graphics, ", 0x"), 69, Player.Serial)
        return nil
    end
    
    -- Select the first container found
    local container = containers[1]
    -- Display information about the found container
    Messages.Overhead(
        "Found container: Serial = " .. container.Serial ..
        ", Name = " .. (container.Name or "Unknown") ..
        ", Graphic = 0x" .. string.format("%04X", container.Graphic),
        69, Player.Serial
    )
    return container
end

-- Function to find all non-container items inside a specified container
function GetContainerItems(containerSerial)
    -- Create a filter to find items strictly inside the given container
    local itemList = Items.FindByFilter({ RootContainer = containerSerial })
    local validItems = {}
    
    -- Check if no items were found in the container
    if not itemList or #itemList == 0 then
        Messages.Overhead("No items found in container: Serial = " .. tostring(containerSerial), 69, Player.Serial)
        return validItems
    end
    
    -- Log the total number of items found before filtering
    Messages.Overhead("Found " .. #itemList .. " items in container", 69, Player.Serial)
    
    -- Iterate through each item in the container
    for _, item in ipairs(itemList) do
        -- Log details of the item being checked
        Messages.Overhead(
            "Checking item: Serial = " .. item.Serial ..
            ", Name = " .. (item.Name or "Unknown") ..
            ", Graphic = 0x" .. string.format("%04X", item.Graphic) ..
            ", IsContainer = " .. tostring(item.IsContainer) ..
            ", RootContainer = " .. tostring(item.RootContainer),
            69, Player.Serial
        )
        
        -- Check if the item's graphic matches any known container graphic
        local isContainerGraphic = false
        for _, graphic in pairs(CONTAINER_GRAPHICS) do
            if item.Graphic == graphic then
                isContainerGraphic = true
                break
            end
        end
        
        -- Filter out invalid items (containers, nested containers by graphic, the container itself, or player's serial)
        if item and not item.IsContainer and not isContainerGraphic and
           item.RootContainer == containerSerial and
           item.Serial ~= containerSerial and
           item.Serial ~= Player.Serial then
            -- Log selected valid item
            Messages.Overhead(
                "Selected item: Serial = " .. item.Serial ..
                ", Name = " .. (item.Name or "Unknown") ..
                ", Graphic = 0x" .. string.format("%04X", item.Graphic),
                69, Player.Serial
            )
            table.insert(validItems, item)
        else
            -- Log why the item was excluded
            Messages.Overhead(
                "Excluded item: IsContainer = " .. tostring(item.IsContainer) ..
                ", IsContainerGraphic = " .. tostring(isContainerGraphic) ..
                ", RootContainer = " .. tostring(item.RootContainer) ..
                ", Serial = " .. tostring(item.Serial),
                69, Player.Serial
            )
        end
    end
    
    -- Log if no valid items were found after filtering
    if #validItems == 0 then
        Messages.Overhead("No valid items found after filtering!", 69, Player.Serial)
    end
    
    return validItems
end

-- Main loop to continuously identify items in a nearby container
while true do
    -- Attempt to find a container (pouch, bag, wooden box, or paragon chest)
    local container = GetContainer()
    
    -- If no container is found, pause and continue to the next iteration
    if not container then
        Messages.Overhead("Pausing before next attempt...", 69, Player.Serial)
        Pause(LOOP_DELAY)
        goto continue
    end
    
    -- Open the container to ensure its contents are accessible
    Messages.Overhead("Opening container: Serial = " .. container.Serial, 69, Player.Serial)
    Player.UseObject(container.Serial)
    Pause(500) -- Wait for the container to open
    
    -- Display start of identification process
    local startText = 'Starting to identify items in container...'
    Messages.Overhead(startText, 69, Player.Serial)
    
    local count = 0 -- Counter for identified items
    
    -- Get all valid non-container items in the container
    local items = GetContainerItems(container.Serial)
    
    -- Iterate through each valid item
    for _, item in ipairs(items) do
        -- Check if the item has a valid name (basic validation)
        local isValidItem = item.Name ~= nil
        if isValidItem then
            -- Log the item being identified
            Messages.Overhead("Identifying item: " .. (item.Name or "Unknown"), 69, Player.Serial)
            
            -- Repeatedly attempt to identify the item until successful
            repeat
                -- Clear journal to check for new messages
                Journal.Clear()
                
                -- Use the Item Identification skill
                Messages.Overhead("Using Item Identification skill...", 69, Player.Serial)
                Skills.Use("Item Identification")
                
                -- Wait for the targeting cursor
                if Targeting.WaitForTarget(GUMP_WAIT_TIMEOUT) then
                    -- Target the item for identification
                    Messages.Overhead("Targeting item: Serial = " .. item.Serial, 69, Player.Serial)
                    Targeting.Target(item.Serial)
                    Pause(ITEM_ID_DELAY) -- Wait for identification to complete
                else
                    -- Log failure to get targeting cursor
                    Messages.Overhead("Failed to use Item Identification! No targeting cursor.", 69, Player.Serial)
                    break
                end
            -- Continue until the journal does not contain "You are not certain"
            until Journal.Contains('You are not certain') == false
            
            count = count + 1 -- Increment counter for successful identification
        end
    end
    
    -- Display completion message with the number of items identified
    local finishText = 'Finished identifying ' .. tostring(count) .. ' items!'
    Messages.Overhead(finishText, 69, Player.Serial)
    
    -- Pause before the next loop iteration
    Messages.Overhead("Pausing before next loop...", 69, Player.Serial)
    Pause(LOOP_DELAY)
    
    ::continue:: -- Label for continuing the loop
end

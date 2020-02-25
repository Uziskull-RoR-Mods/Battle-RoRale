-- local popup = {w = 50, h = 30}

-- local function lobbyWarning(window, frames)
    -- local data = window:getData()
    -- local hudW, hudH = graphics.getGameResolution()
    -- local mouseX, mouseY = input.getMousePos()
    -- if frames == 1 or data.prevHudH ~= hudH then
        -- window.x, window.y = hudW - 16 - 50
    -- end
-- end

-- registercallback("globalRoomStart", function(room)
    -- if room:getOrigin() ~= "Vanilla" then return end
    -- if room:getName() == "SelectMult" then
        -- graphics.bindDepth(-10, lobbyWarning)
    -- end
-- end)

function generatingStage(inst, frames)
    local stageList = {}
    for part, _ in pairs(Map.parts) do
        table.insert(stageList, part)
    end
    graphics.color(Color.BLACK)
    local hudW, hudH = graphics.getGameResolution()
    graphics.rectangle(0, 0, hudW, hudH)
    graphics.color(Color.WHITE)
    if frames == 1 then
    
    elseif frames == 2 then
        graphics.print("GENERATING STAGE...", hudW / 2, hudH / 2,
          graphics.FONT_LARGE, graphics.ALIGN_MIDDLE, graphics.ALIGN_CENTER)
        -- create stage
        local stage = Map.setupStage()
    elseif frames <= 2 + #stageList then
        graphics.print("GENERATING MAP... ("..(frames - 2).."/"..#stageList..")", hudW / 2, hudH / 2,
          graphics.FONT_LARGE, graphics.ALIGN_MIDDLE, graphics.ALIGN_CENTER)
        -- create map
        Map.createMap(stageList[frames - 2])
    else
        inst:destroy()
    end
end

registercallback("globalRoomStart", function(room)
    if Map.stage == nil then
        if room:getOrigin() ~= "Vanilla" then return end
        if room:getName() == "Start" then
            graphics.bindDepth(-999999999, generatingStage)
        end
    end
end)
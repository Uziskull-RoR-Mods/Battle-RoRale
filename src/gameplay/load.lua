-----------------
-- Sync Coords --
-----------------
local syncDone = false
registercallback("onGameEnd", function()
    syncDone = false
end)
syncCoordsPacket = net.Packet("Sync Coords", function(_, x, y)
    net.localPlayer.x, net.localPlayer.y = x, y
    syncDone = true
end)

function gameStartStuff(inst, frames)
    local currStage = Stage.getCurrentStage()
    if currStage ~= Map.stage then
        inst:destroy()
        return
    end
    if frames == 1 then
        -- -- assign different teams for every player
        -- for _, p in ipairs(misc.players) do
            -- p:set("team", "team"..p.playerIndex)
        -- end
        -- make everyone else an enemy
        local localPlayer = net.online and net.localPlayer or misc.players[1]
        for _, p in ipairs(misc.players) do
            if p ~= localPlayer then
                p:set("team", "succ")
            end
        end
        
        -- hide tp away
        local tp = Object.find("Teleporter", "Vanilla"):find(1)
        if tp ~= nil then
            tp.x, tp.y = 0, 0
            tp.alpha = 0
            tp:set("locked", 1)
        end
        tp = Object.find("TeleporterFake", "Vanilla"):find(1)
        tp.alpha = 0
        
        if net.host then
            syncDone = true
            -- spread players
            -- this is slow and not smart but its 4am and i really dont care
            local quadrants = {}
            for i = 0, 15 do table.insert(quadrants, i) end
            -- fisher-yates it
            for i = #quadrants, 2, -1 do
                local j = math.random(i)
                quadrants[i], quadrants[j] = quadrants[j], quadrants[i]
            end
            for i, p in ipairs(misc.players) do
                local xx, yy = quadrants[i] % 4, math.floor(quadrants[i] / 4)
                local blist = Object.find("B", "Vanilla"):findAllRectangle(xx * 1500, yy * 1500, (xx + 1) * 1500, (yy + 1) * 1500)
                local b = blist[math.random(#blist)]
                local px, py = b.x + 8, b.y - 1 - (p.sprite.height - p.sprite.yorigin)
                
                p.x, p.y = px, py
                if net.online and p ~= net.localPlayer then
                    syncCoordsPacket:sendAsHost(net.DIRECT, p, px, py)
                end
            end
            
            -- boost spawns, hell ye
            misc.director:set("bonus_rate", misc.director:get("bonus_rate") + 5)
        end
    end
    if syncDone then
        inst:destroy()
    else
        graphics.color(Color.BLACK)
        graphics.rectangle(
            camera.x - 5, camera.y - 5,
            camera.x + camera.width + 5, camera.y + camera.height + 5
        )
    end
end

registercallback("onStageEntry", function()
    local handler = graphics.bindDepth(-100000000, gameStartStuff)
end)
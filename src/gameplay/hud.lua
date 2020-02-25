-------------------------
-- Hide Player Bubbles --
-------------------------
-- bubbles arent drawn if players are dead, so just mark em as dead while drawing HUD lmao
registercallback("preHUDDraw", function()
    for _, p in ipairs(misc.players) do
        p:getData().dead = p:get("dead")
        p:set("dead", 1)
    end
end)
registercallback("onHUDDraw", function()
    for _, p in ipairs(misc.players) do
        p:set("dead", p:getData().dead)
    end
end)

-----------------
-- General HUD --
-----------------
registercallback("onHUDDraw", function()
    local currStage = Stage.getCurrentStage()
    if currStage == Map.stage then
        local hudW, hudH = graphics.getHUDResolution()
        -- anti zoomies check
        if flags.lock_zoom then
            local gameW, gameH = graphics.getGameResolution()
            local max_scale = math.min(math.floor(gameW / 576), math.floor(gameH / 360))
            if misc.getOption("video.scale") ~= max_scale then
                graphics.color(Color.BLACK)
                graphics.rectangle(0, 0, hudW, hudH)
                graphics.color(Color.WHITE)
                graphics.print(
                    "Uh-oh!", hudW / 2, hudH / 2 - 20,
                    graphics.FONT_LARGE, graphics.ALIGN_MIDDLE, graphics.ALIGN_CENTER
                )
                for i = 1, 3 do
                    local yy = -8 + (i - 1) * 8
                    local text = {
                        "The game host locked zoom to prevent some",
                        "players from having an advantage over others.",
                        "Please use the maximum zoom scale available."
                    }
                    graphics.print(
                        text[i], hudW / 2, hudH / 2 + yy,
                        graphics.FONT_DEFAULT, graphics.ALIGN_MIDDLE, graphics.ALIGN_CENTER
                    )
                end
            end
        end
        
        -- player count
        local alive = #Object.find("P", "Vanilla"):findMatching("dead", 0)
        misc.hud:set("objective_text", "Players remaining: " .. alive)
    end
end)
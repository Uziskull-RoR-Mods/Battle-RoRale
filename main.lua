-----------
-- Flags --
-----------
flags = {
    lock_zoom = true
}
for flag, _ in pairs(flags) do
    local savedVal = save.read(flag)
    if savedVal ~= nil then
        flags[flag] = savedVal
    end
end

-------------
-- Imports --
-------------
require("src/pre")

require("src/gameplay/map")
require("src/gameplay/load")
require("src/gameplay/hud")
require("src/gameplay/game")

-----------
-- Debug --
-----------
debug = true
if debug then
    -- registercallback("onDraw", function()
        -- graphics.color(Color.RED)
        -- graphics.line(camera.x + camera.width / 2, camera.y + camera.height / 2 + 5, camera.x + camera.width / 2, camera.y + camera.height / 2 - 5)
        -- graphics.line(camera.x + camera.width / 2 - 5, camera.y + camera.height / 2, camera.x + camera.width / 2 + 5, camera.y + camera.height / 2)
    -- end)

    -- registercallback("onPlayerStep", function(player)
        -- player:set("pHspeed", 5):set("pVspeed", 0)
        -- for i, d in ipairs({"up", "down"}) do
            -- if player:control(d) == input.HELD then
                -- player.y = player.y + (i == 1 and -1 or 1) * 5
                -- break
            -- end
        -- end
    -- end)
    local ts, col = false, false
    registercallback("onStep", function()
        if input.checkMouse("left") == input.PRESSED then
            local mx, my = input.getMousePos()
            misc.players[1].x, misc.players[1].y = mx, my
        end
        if input.checkKeyboard("numpad5") == input.PRESSED then
            --Object.find("Lizard"):create(net.localPlayer.x, net.localPlayer.y)
            for _, p in ipairs(misc.players) do
                p.x, p.y = 160, 160
            end
        end
        if input.checkKeyboard("numpad6") == input.PRESSED then
            ts = not ts
        end
        if ts then
            misc.setTimeStop(2)
        end
    end)
    registercallback("onDraw", function()
        if input.checkKeyboard("numpad4") == input.PRESSED then
            col = not col
        end
        if col then
            for _, p in ipairs(misc.players) do
                graphics.color(Color.BLACK)
                graphics.print("X: " .. p.x, p.x, p.y - 14)
                graphics.print("Y: " .. p.y, p.x, p.y - 7)
                graphics.color(Color.PINK)
                for _, b in ipairs(Object.find("B", "Vanilla"):findAllEllipse(p.x - 10, p.y - 10, p.x + 10, p.y + 10)) do
                    graphics.rectangle(b.x, b.y, b.x + 16, b.y + 16)
                end
                graphics.color(Color.RED)
                graphics.rectangle(
                    p.x - p.sprite.xorigin,
                    p.y - p.sprite.yorigin,
                    p.x - p.sprite.xorigin + p.sprite.width,
                    p.y - p.sprite.yorigin + p.sprite.height
                )
            end
        end
    end)
end
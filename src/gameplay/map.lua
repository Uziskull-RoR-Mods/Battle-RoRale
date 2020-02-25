-----------------------------------------
-- Map:
-- 
-- +-----------++----------++-----------+
-- |           ||          ||           |
-- |           ||          ||           |
-- |    LL     ||    CC    ||    MM     |
-- | 2k x 2.4k || 2k x 2.4k|| 2k x 2.4k |
-- |           ||          ||           |
-- +-----------++----------++-----------+
-- +-----------++-----------------------+
-- |           ||                       |
-- |           ||           DD          |
-- |           ||        4k x 2k        |
-- |           ||                       |
-- |     RR    |+-----------------------+
-- |  2k x 4k  |+-----------------------+
-- |           ||                       |
-- |           ||           HH          |
-- |           ||        4k x 2k        |
-- |           ||                       |
-- +-----------++-----------------------+
-- 
--              6000 x 6400
--
-----------------------------------------

local MAP_OFFSET = 25
local OBJ_PALETTE = {
    o = { Object.find("B", "Vanilla") },
    X = { Object.find("BNoSpawn", "Vanilla") },
    B = { Object.find("BossSpawn", "Vanilla"), Object.find("B", "Vanilla") },
    r = { Object.find("Rope", "Vanilla") },
    R = { Object.find("Rope", "Vanilla"),   Object.find("B", "Vanilla") },
    C = { Object.find("Rope", "Vanilla"),   Object.find("BNoSpawn", "Vanilla") },
    g = { Object.find("Geyser", "Vanilla"), Object.find("B", "Vanilla") },
    G = { Object.find("Geyser", "Vanilla"), Object.find("BNoSpawn", "Vanilla") },
    l = { Object.find("Lava", "Vanilla") },
}

Map = {}
Map.parts = {
    ll = {
        x=0,      y=0,    width=2000,     height=2400,
        enemies = Stage.progression[3][2].enemies:toTable()
    },
    cc = {
        x=2000,   y=0,    width=2000,     height=2400,
        enemies = Stage.progression[5][1].enemies:toTable()
    },
    mm = {
        x=4000,   y=0,    width=2000,     height=2400,
        enemies = Stage.progression[2][2].enemies:toTable()
    },
    rr = {
        x=0,      y=2400, width=2000,     height=4000,
        enemies = Stage.progression[2][1].enemies:toTable()
    },
    dd = {
        x=2000,   y=2400, width=4000,     height=2000,
        enemies = Stage.progression[4][2].enemies:toTable()
    },
    hh = {
        x=2000,   y=4400, width=4000,     height=2000,
        enemies = Stage.progression[4][1].enemies:toTable()
    }
}
Map.sprites = {}

for part, _ in pairs(Map.parts) do
    Map.parts[part].map = require("maps/" .. part)
end

function Map.setupStage()
    local room = Room.find("BR_Room", modloader.getActiveNamespace())
    if room == nil then
        room = Room.new("BR_Room")
        room:resize(6000, 6400) -- TODO: mess around with level warping
        for _, part in pairs(Map.parts) do
            for yy, row in ipairs(part.map) do
                -- optimization for empty lines
                local ss, se = row:find("%s*")
                if not (ss == 1 and se == row:len()) then
                    local xx = 1
                    for char in row:gmatch(".") do
                        if char ~= " " then
                            for _, obj in ipairs(OBJ_PALETTE[char]) do
                                local offset = obj == OBJ_PALETTE.r[1] and 8 or 0
                                room:createInstance(obj, part.x + (xx - 1) * 16 + offset, part.y + (yy - 1) * 16)
                            end
                        end
                        xx = xx + 1
                    end
                end
            end
        end
    end
    local stage = Stage.find("BR_Stage", modloader.getActiveNamespace())
    --local currLimit = Stage.progressionLimit()
    --if stage == nil or Stage.getProgression(currLimit)[1] ~= stage then
    if stage == nil or Stage.progression[1][1] ~= stage then
        stage = stage or Stage.new("BR_Stage")
        stage.rooms:add(room)
        stage.displayName = "gl&hf plebs"
        stage.music = Sound.find("HitItSon", "Vanilla")
        for _, thing in ipairs({"enemies", "interactables"}) do
            local thingList = Stage.progression[1][1][thing]
            for i = 1, thingList:len() do
                stage[thing]:add(thingList[i])
            end
        end
        local thingMap = Stage.progression[1][1].interactableRarity:toTable()
        for k, v in pairs(thingMap) do
            stage.interactableRarity[k] = v
        end
        
        --Stage.progressionLimit(currLimit + 1)
        --local stageList = Stage.getProgression(currLimit + 1)
        --stageList:add(stage)
        local stageList = Stage.progression[1]:toTable()
        for _, s in ipairs(stageList) do
            Stage.progression[1]:remove(s)
        end
        Stage.progression[1]:add(stage)
    end
    Map.stage = stage
end

function Map.createMap(part)
    local partSpr = Sprite.find("BR_"..part, modloader.getActiveNamespace())
    if partSpr ~= nil then
        Map.sprites[part] = partSpr
        return
    end
    if part == nil or part ~= "ll" or part ~= "cc" or part ~= "mm"
      or part ~= "rr" or part ~= "dd" or part ~= "hh" then
        local surf = Surface.new(Map.parts[part].width, Map.parts[part].height)
        graphics.setTarget(surf)
        if part == "ll" then
            graphics.color(Color.ROR_BLUE)
        elseif part == "cc" then
            graphics.color(Color.ROR_GREEN)
        elseif part == "mm" then
            graphics.color(Color.ROR_RED)
        elseif part == "rr" then
            graphics.color(Color.ROR_YELLOW)
        elseif part == "dd" then
            graphics.color(Color.ROR_ORANGE)
        elseif part == "hh" then
            graphics.color(Color.CORAL)
        end
        graphics.rectangle(0, 0, surf.width, surf.height)
        
        for yy, row in ipairs(Map.parts[part].map) do
            -- optimization for empty lines
            local ss, se = row:find("%s*")
            if not (ss == 1 and se == row:len()) then
                local xx = 1
                for char in row:gmatch(".") do
                    if char ~= " " and char ~= "r" then
                        graphics.color(char == "r" and Color.CYAN or Color.BLACK)
                        graphics.rectangle(
                            (xx - 1) * 16, (yy - 1) * 16,
                            (xx - 1) * 16 + 16, (yy - 1) * 16 + 16
                        )
                    end
                    xx = xx + 1
                end
            end
        end
        
        graphics.resetTarget()
        partSpr = surf:createSprite(0, 0)
        surf:free()
    end
    if partSpr ~= nil then
        Map.sprites[part] = partSpr:finalize("BR_"..part)
    end
end

function Map.drawPart()
    local allParts = {}
    for part, _ in pairs(Map.parts) do
        table.insert(allParts, part)
    end
    local cameraCorners = {
        {x=camera.x, y=camera.y}, {x=camera.x + camera.width, y=camera.y}, 
        {x=camera.x, y=camera.y + camera.height}, {x=camera.x + camera.width, y=camera.y + camera.height}
    }
    local partList = {}
    for _, cameraCorner in ipairs(cameraCorners) do
        local checkParts = {}
        for _, p1 in ipairs(allParts) do
            local alreadyChecked = false
            for _, p2 in ipairs(partList) do
                if p1 == p2 then
                    alreadyChecked = true
                    break
                end
            end
            if not alreadyChecked then
                table.insert(checkParts, p1)
            end
        end
        for _, part in ipairs(checkParts) do
            local dim = Map.parts[part]
            if cameraCorner.x >= dim.x - MAP_OFFSET and cameraCorner.y >= dim.y - MAP_OFFSET
              and cameraCorner.x <= dim.x + dim.width + MAP_OFFSET and cameraCorner.y >= dim.y - MAP_OFFSET
              and cameraCorner.x >= dim.x - MAP_OFFSET and cameraCorner.y <= dim.y + dim.height + MAP_OFFSET
              and cameraCorner.x <= dim.x + dim.width + MAP_OFFSET and cameraCorner.y <= dim.y + dim.height + MAP_OFFSET then
                table.insert(partList, part)
            end
        end
    end
    for _, part in ipairs(partList) do
        Map.sprites[part]:draw(Map.parts[part].x, Map.parts[part].y)
    end
end

export("Map")
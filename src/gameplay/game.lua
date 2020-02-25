----------------
-- Map Stuffs --
----------------
function mapManager(inst, _)
    -- draw map layers
    Map.drawPart()
    
    -- save players' current area
    for _, p in ipairs(misc.players) do
        local curPart = "cc" -- fallback
        for part, dim in pairs(Map.parts) do
            if p.x >= dim.x and p.x < dim.x + dim.width
              and p.y >= dim.y and p.y < dim.y + dim.height then
                curPart = part
                break
            end
        end
        p:getData().area = curPart
    end
end
registercallback("onStageEntry", function()
    graphics.bindDepth(20, mapManager)
end)

---------------------------
-- Sides Map Teleporting --
---------------------------
registercallback("onPlayerStep", function(p)
    local stageW, _ = Stage.getDimensions()
    if p.x < 0 then
        p.x = stageW + p.x
    elseif p.x > stageW then
        p.x = p.x - stageW
    end
end)

---------------------
-- Custom Director --
---------------------
local prevPlayer, nextPlayer, rollback = nil, nil, false
registercallback("preStep", function()
    if net.host then
        if prevPlayer == nil then
            -- first time
            prevPlayer, nextPlayer = misc.players[1], misc.players[1]
        end
        local alarm = misc.director:getAlarm(1)
        -- about to spawn
        if alarm == 1 then
            local pickedPlayer = rollback and prevPlayer or nextPlayer
            
            local alivePlayers = {} --Object.find("P", "Vanilla"):findMatching("dead", 0)
            for _, p in ipairs(misc.players) do
                if p:get("dead") == 0 then
                    table.insert(alivePlayers, p)
                end
            end
            
            if pickedPlayer == nil then
                -- ah fug someone disconnected
                misc.director:set("count", 0)
                local newPlayer = alivePlayers[math.random(#alivePlayers)]
                prevPlayer, nextPlayer, pickedPlayer = newPlayer, newPlayer, newPlayer
            end
            
            -- "kill" all players except for the previously picked one
            for _, p in ipairs(alivePlayers) do
                if p ~= pickedPlayer then
                    p:getData().toggleDead = true
                    p:set("dead", 1)
                end
            end
            
            if not rollback then
                -- save this guy just in case of multiple spawns
                prevPlayer = nextPlayer
                
                -- pick new player for the next round
                nextPlayer = alivePlayers[math.random(#alivePlayers)]
                
                -- delete previous enemies
                local currEnemies = Map.stage.enemies:toTable()
                for i = 1, #currEnemies do
                    Map.stage.enemies:remove(currEnemies[i])
                end
                
                if nextPlayer ~= nil then
                    -- add ones in player's area
                    local enemyList = {}
                    for _, enemy in ipairs(Map.parts[nextPlayer:getData().area].enemies) do
                        local alreadyIn = false
                        for _, e in ipairs(enemyList) do
                            if enemy == e then
                                alreadyIn = true
                                break
                            end
                        end
                        if not alreadyIn then
                            Map.stage.enemies:add(enemy)
                            table.insert(enemyList, enemy)
                        end
                    end
                end
            end
            
            rollback = false
        end
    end
end, -999999999)
registercallback("onStep", function()
    if net.host then
        local checkCount = false
        for _, p in ipairs(misc.players) do
            local playerData = p:getData()
            if playerData.toggleDead then
                if not checkCount then
                    checkCount = true
                    
                    local count = misc.director:get("count")
                    if count > 0 then
                        -- director decided to multispawn; roll back enemy list and player
                        rollback = true
                    end
                end
                p:set("dead", 0)
                playerData.toggleDead = nil
            end
        end
    end
end, 999999999)

-----------------------
-- Stop Shared Drops --
-----------------------
local dropObjs = {
    Object.find("EfGold", "Vanilla"),
    Object.find("EfExp", "Vanilla"),
    Object.find("EfHeal", "Vanilla"),
    Object.find("EfHeal2", "Vanilla")
}
for _, obj in ipairs(dropObjs) do
    obj:addCallback("create", function(self)
        local closestPlayer = Object.find("P", "Vanilla"):findNearest(self.x, self.y)
        if closestPlayer ~= nil then
            self:set("target", closestPlayer.id)
        end
    end)
end

-------------------
-- Friendly Fire --
-------------------
-- registercallback("onFire", function(damager)
    -- local parent = damager:getParent()
    -- if isa(parent, "PlayerInstance") then
        -- damager:set("team", "team"..parent.playerIndex)
    -- end
-- end, 9999999999)

-- TODO: manually change stuff that needs to be changed
-- items: tqwibs, bomb, etc etc
-- possible problems:
--
-- »» TO BE DONE: ««
--     huntress boomerang (HuntressBoomerang) [basically copy-pasta code on "oEnemy" collision, but make it trigger for players,
--   to deal with not hitting players multiple times keep track of hit players in getData()]
--     hyperthreader item (EfBlaster) [same approach as HuntressBoomerang]
--     acrid's poison (Dot2, possibly also FeralDisease and FeralDisease2)
--     acrid's space aids (EfPoison) [pretty sure its enough to set target enemy/player as "parent" on create callback]
--     vagrant cytoclast item thing (JellyMissileFriendly) [set closest enemy/player as "target" on create callback]
--     sniper's drone (SniperDrone) [everytime "tt" changes, if it changes to non-negative, set it to the closest enemy/player with highest hp (dist has to be < 480)]
--     han-d's drones (JanitorBaby) [repeat condition (state=2) after step ends, check for collision against players as well (except for the one that fired this)]
--     merc's ult [everytime merc's "ult_target" changes, if it changes to non-negative, set it to closest enemy/player with dist < 100]

local function getClosestEnemy(parent, maxDistance, prioritizeHealth)
    local currEnemy, currDistCmp, currHp = nil, nil, nil
    local enemies = ParentObject.find("enemies", "Vanilla"):findAll()
    for _, p in ipairs(misc.players) do
        table.insert(enemies, p)
    end
    for _, enemy in ipairs(enemies) do
        if enemy ~= parent then
            local distCmp = (enemy.x - parent.x)*(enemy.x - parent.x) + (enemy.y - parent.y)*(enemy.y - parent.y)
            local hp = prioritizeHealth ~= nil and enemy:get("maxhp") or nil
            if currEnemy == nil
              or ((maxDistance == nil or (maxDistance ~= nil and distCmp < maxDistance*maxDistance))
              and (prioritizeHealth ~= nil and (hp > currHp or (hp == currHp and distCmp < currDistCmp)) or (distCmp < currDistCmp))) then
                currEnemy, currDistCmp, currHp = enemy, distCmp, hp
            end
        end
    end
    return currEnemy
end

-- registercallback("preStep", function()
    -- -- since literally 70% of the fired bullets in the game hardcode team values instead of using parent values:tm:
    -- for _, damager in ipairs(Object.find("Bullet", "Vanilla"):findAll()) do
        -- local parent = Object.findInstance(inst:get("parent"))
        -- if parent ~= nil then
            -- local suffix = damager:get("team"):sub(-4) == "proc" and "proc" or ""
            -- damager:set("team", parent:get("team") .. suffix)
        -- end
    -- end
-- end, 10000)

local missileObjs = {
    Object.find("EngiHarpoon", "Vanilla"),
    Object.find("EfMissile", "Vanilla"),
    Object.find("EfFirework", "Vanilla"),
    Object.find("EfMissileSmall", "Vanilla"),
    Object.find("EfMissileMagic", "Vanilla")
}
local moreStuff = {
    Object.find("EngiTurret", "Vanilla")
}
registercallback("preStep", function()
    for _, obj in ipairs(missileObjs) do
        for _, inst in ipairs(obj:findAll()) do
            local alarm = inst:getAlarm(2)
            -- if about to trigger
            if alarm == 1 then
                inst:setAlarm(2, -1)
                local parent = inst
                local dist = nil
                -- in the case of engi's missiles, the enemy is relative to the player's pos
                if obj == missileObjs[1] then
                    parent = Object.findInstance(inst:get("parent"))
                    dist = 600
                end
                local nearbyEnemy = getClosestEnemy(parent, dist)
                if nearbyEnemy ~= nil then
                    inst:set("target", nearbyEnemy.id)
                end
                -- in the case of engi's missiles, if no enemy is found then destroy it
                if obj == missileObjs[1] and nearbyEnemy == nil then
                    inst:destroy()
                end
            end
        end
    end
    
    -- engi turret
    for _, inst in ipairs(moreStuff[1]:findAll()) do
        local alarm = inst:getAlarm(0)
        -- if about to trigger
        if alarm == 1 then
            if inst:get("state") == "idle" then
                local parent = Object.findInstance(inst:get("parent"))
                -- set team accordingly if you havent already
                local instData = inst:getData()
                if instData.setup == nil then
                    inst:set("team", parent:get("team"))
                    instData.setup = true
                end
                local list = Object.find("P", "Vanilla"):findAllLine(inst.x - 300, inst.y, inst.x + 300, inst.y)
                for _, p in ipairs(list) do
                    if p ~= parent then
                        inst:set("state", "chase")
                            :set("target", p.id)
                        inst:setAlarm(0, 15 + 1)
                        break
                    end
                end
            end
        end
    end
end)

local enemyContact = {
    Object.find("RiotGrenade", "Vanilla"),     -- enforcer grenade
    Object.find("CowboyDynamite", "Vanilla"),  -- bandit grenade
    Object.find("ChefKnife", "Vanilla"),       -- chef knife
    Object.find("HuntressBolt1", "Vanilla"),   -- huntress bolt
    Object.find("HuntressBolt2", "Vanilla"),   -- huntress bolt
    Object.find("HuntressBolt3", "Vanilla"),   -- huntress bolt
    Object.find("EngiMine", "Vanilla"),        -- engi mines
    Object.find("EngiGrenade", "Vanilla"),     -- engi grenades
    
}
registercallback("onStep", function()
    -- stuff that gets destroyed on hit
    for _, obj in ipairs({enemyContact[1], enemyContact[2], enemyContact[8]}) do
        for _, inst in ipairs(obj:findAll()) do
            local parent = Object.findInstance(inst:get("parent"))
            for _, p in ipairs(misc.players) do
                if parent ~= nil and p ~= parent and inst:collidesWith(p, inst.x, inst.y) then
                    inst:destroy()
                    break
                end
            end
        end
    end
    
    -- engi missiles
    for _, inst in ipairs(missileObjs[1]:findAll()) do
        local parent = Object.findInstance(inst:get("parent"))
        for _, p in ipairs(misc.players) do
            if parent ~= nil and p ~= parent and inst:collidesWith(p, inst.x, inst.y) then
                parent:fireBullet(p.x, p.y, inst:get("direction"), 5, 2.5, Sprite.find("Sparks1","Vanilla"))
                if misc.getOption("video.quality") == 3 then
                    local fx = Object.find("EfBullet2", "Vanilla"):create(inst.x, inst.y)
                    fx.sprite = Sprite.find("EfMissileExplosion", "Vanilla")
                    fx.spriteSpeed = 0.3
                end
                inst:destroy()
                break
            end
        end
    end
    
    -- chef knives
    for _, inst in ipairs(enemyContact[3]:findAll()) do
        local instData = inst:getData()
        if instData.prevX == nil then
            instData.prevX = inst.x
        end
        local parent = Object.findInstance(inst:get("parent"))
        for _, p in ipairs(misc.players) do
            if parent ~= nil and p ~= parent and inst:collidesWith(p, inst.x, inst.y) then
                local hit = false
                if instData.hit == nil then
                    instData.hit = {}
                end
                for _, h in ipairs(instData.hit) do
                    if p == h then
                        hit = true
                        break
                    end
                end
                if not hit then
                    if #instData.hit < 25 then
                        table.insert(instData.hit, p)
                    end
                    
                    Sound.find("Crit", "Vanilla"):play(
                        misc.getOption("general.volume") * 0.8,
                        0.6 + math.random() * 0.2
                    )
                    local fx = Object.find("EfBullet2", "Vanilla"):create(p.x,p.y)
                    fx.sprite = Sprite.find("EfSlash2", "Vanilla")
                    local knife = nil
                    if inst:get("damage") == inst:get("true_damage") then
                        knife = parent:fireExplosion(inst.x - math.sign(p.x - instData.prevX)*9, p.y, 1, 1, 1,
                            nil, Sprite.find("Sparks1", "Vanilla"))
                    else
                        knife = parent:fireExplosion(inst.x - math.sign(p.x - instData.prevX)*9, p.y, 1, 1, 1,
                            nil, Sprite.find("Sparks1", "Vanilla"), DAMAGER_NO_PROC)
                        knife:set("team", "playerproc")
                    end
                    knife:set("specific_target", p.id)
                    inst:set("damage", math.ceil(math.max(inst:get("damage") - (inst:get("true_damage")*0.35), inst:get("true_damage")*0.1)))
                end
                break
            end
        end
        instData.prevX = inst.x
    end
    
    -- huntress bolts
    for _, obj in ipairs({enemyContact[4], enemyContact[5], enemyContact[6]}) do
        for _, inst in ipairs(obj:findAll()) do
            if obj == enemyContact[4] then
                inst:getData().prevX = inst:getData().prevX == nil and inst.x or inst:getData().prevX + 1
            end
            local parent = Object.findInstance(inst:get("parent"))
            for _, p in ipairs(misc.players) do
                if parent ~= nil and p ~= parent and inst:collidesWith(p, inst.x, inst.y) then
                    parent:set("target", p.id)
                    if obj == enemyContact[4] then
                        local bolt = parent:fireBullet(inst.x - math.sign(p.x - inst:getData().prevX)*9, p.y,
                            90 - (90 * math.sign(inst.x - inst:getData().prevX)), 18, 3.2, Sprite.find("Sparks1","Vanilla"))
                        bolt:set("climb", inst:get("climb")):set("specific_target", p.id)
                    end
                    inst:destroy()
                    break
                end
            end
            if obj == enemyContact[4] then
                inst:getData().prevX = inst.x
            end
        end
    end
    
    -- engi mines
    for _, inst in ipairs(enemyContact[7]:findAll()) do
        local parent = Object.findInstance(inst:get("parent"))
        for _, p in ipairs(misc.players) do
            if parent ~= nil and p ~= parent and inst:collidesWith(p, inst.x, inst.y) then
                if inst:get("active") == 1 then
                    Sound.find("GiantJellyExplosion", "Vanilla"):play(misc.getOption("general.volume"), 3)
                    inst:set("active", 2)
                    inst.sprite = Sprite.find("EngiMineJump", "Vanilla")
                    inst.subimage = 1
                    inst.spriteSpeed = 0.3
                end
                break
            end
        end
    end
end)
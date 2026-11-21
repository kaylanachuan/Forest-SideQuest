levels = {
    forestEntrance = {
        map = 'maps/forestEntrance.lua',
        spawn = {x = 400, y = 200},
        npc = {name = "Best Friend", x = 500, y = 200, knot = "opening"},
        exits = {
            {x = 1850, y = 935, w = 300, h = 300, to = "witchHouse"},
        },
    },
    witchHouse = {
        map = 'maps/witchHouse.lua',
        spawn = {x = 65, y = 940},
        npc = {name = "Witch", x = 905, y = 915, knot = "WitchDialogue"},
        exits = {
            {x = 1880, y = 950, w = 500, h = 500, to = "bigRed"}
            },
    },
    bigRed = {
        map = 'maps/bigRed.lua',
        spawn = {x = 65, y = 940},
        npc = {name = "BigRed", x = 1250, y = 920, knot = "BigRedDialogue"},
        exits = {
            {x = 1845, y = 1120, w = 500, h = 500, gameover = true},
            {x = 1855, y = 660, w = 500, h = 500, to = "flowerField"},
        },
    },
    flowerField = {
        map = 'maps/flowerField.lua',
        spawn = {x = 65, y = 940},
        npc = {name = "Mimic", x = 1180, y = 915, knot = "MimicDialogue"},
        exits = {},
    },
}

function loadLevel(name)
    local lvl = levels[name]
    currentLevel = lvl
    gameMap = sti(lvl.map)

    player.x, player.y = lvl.spawn.x, lvl.spawn.y

    narrator._boundNPCs = {}  -- forget the previous level's NPCs
    myNPC = NPC.new('sprites/player-sheet.png', lvl.npc.x, lvl.npc.y, 0, 0)
    local char = narrator:newCharacter(lvl.npc.name, nil)
    narrator:bindNPC(myNPC, char, lvl.npc.knot)
end

gameState = "playing"

function triggerGameOver()
    gameState = "gameover"
end

function restartGame()
    gameState = "playing"
    loadLevel("forestEntrance")
end

function love.load()
    camera = require 'libraries/camera'
    NPC = require 'libraries/npc'
    anim8 = require 'libraries/anim8'
    sti = require 'libraries/sti'
    narrator = require 'libraries/narrator'

    cam = camera()
    cam:zoomTo(0.5)

    love.graphics.setDefaultFilter("nearest", "nearest")

    player = {}
    player.speed = 5
    player.spriteSheet = love.graphics.newImage('sprites/player-sheet.png')
    player.grid = anim8.newGrid( 12, 18, player.spriteSheet:getWidth(), player.spriteSheet:getHeight() )

    player.animations = {}
    player.animations.down = anim8.newAnimation( player.grid('1-4', 1), 0.2 )
    player.animations.left = anim8.newAnimation( player.grid('1-4', 2), 0.2 )
    player.animations.right = anim8.newAnimation( player.grid('1-4', 3), 0.2 )
    player.animations.up = anim8.newAnimation( player.grid('1-4', 4), 0.2 )

    player.anim = player.animations.left

    narrator:init()

    interactRange = 200
    nearbyNPC = nil
    promptFont = love.graphics.newFont(14)

    -- must come after player and narrator:init() exist
    loadLevel("forestEntrance")
end

-- Check if a world position collides with a tile on the Trees layer
function treeAt(x, y)
    local layer = gameMap.layers["Trees"]
    local tx = math.floor(x / gameMap.tilewidth) + 1
    local ty = math.floor(y / gameMap.tileheight) + 1
    local t = layer.data[ty] and layer.data[ty][tx]
    return t and t.gid ~= 14 and t.gid ~= nil
end

-- Find the closest bound NPC within interactRange (or nil).
function findNearbyNPC()
    local closest, closestDist = nil, interactRange
    for _, npc in ipairs(narrator._boundNPCs) do
        local dx = npc.x - player.x
        local dy = npc.y - player.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist <= closestDist then
            closest, closestDist = npc, dist
        end
    end
    return closest
end

function love.update(dt)
    if gameState == "gameover" then return end
    local dialogueOpen = narrator:isOpen()

    -- Freeze the player while a dialog is on screen so the conversation feels
    -- grounded. NPCs are paused via narrator:bindNPC's update wrapper.
    if not dialogueOpen then
        local isMoving = false
        local oldX, oldY = player.x, player.y

        if love.keyboard.isDown("right") then
            player.x = player.x + player.speed
            player.anim = player.animations.right
            isMoving = true
        end

        if love.keyboard.isDown("left") then
            player.x = player.x - player.speed
            player.anim = player.animations.left
            isMoving = true
        end

        if love.keyboard.isDown("down") then
            player.y = player.y + player.speed
            player.anim = player.animations.down
            isMoving = true
        end

        if love.keyboard.isDown("up") then
            player.y = player.y - player.speed
            player.anim = player.animations.up
            isMoving = true
        end

        -- Collision: check each axis separately so player slides along walls
        if treeAt(player.x, oldY + 50) then player.x = oldX end
        if treeAt(player.x, player.y + 50) then player.y = oldY end

        -- Level exits: walk into an exit box to load the next level
        for _, e in ipairs(currentLevel.exits) do
            if player.x > e.x and player.x < e.x + e.w
               and player.y > e.y and player.y < e.y + e.h then
                loadLevel(e.to)
                break
            end
        end

        if isMoving == false then
            player.anim:gotoFrame(2)
        end
    else
        -- Hold the idle pose during conversation.
        player.anim:gotoFrame(2)
    end

    player.anim:update(dt)

    -- Update camera position
    cam:lookAt(player.x, player.y)

    -- This section prevents the camera from viewing outside the background
    local w, h = love.graphics.getDimensions()

    local mapW = gameMap.width * gameMap.tilewidth
    local mapH = gameMap.height * gameMap.tileheight

    local zoom = 0.5
    local halfW = w / (2 * zoom)
    local halfH = h / (2 * zoom)

    cam.x = math.max(halfW, math.min(cam.x, mapW - halfW))
    cam.y = math.max(halfH, math.min(cam.y, mapH - halfH))
    myNPC:update(dt)

    -- Refresh proximity once per frame, only when no dialog is showing.
    if dialogueOpen then
        nearbyNPC = nil
    else
        nearbyNPC = findNearbyNPC()
    end

    narrator:update(dt)
end

-- Small "E" key hint floating above an NPC's head.
function drawInteractPrompt(npc)
    love.graphics.setColor(1, 1, 1)
    love.graphics.push()
    love.graphics.translate(npc.x - 45, npc.y - 80)
    love.graphics.scale(2, 2)
    love.graphics.print("Press E", 0, 0)
    love.graphics.pop()
end

function love.draw()
    cam:attach()
     gameMap:drawLayer(gameMap.layers["Ground"])
     gameMap:drawLayer(gameMap.layers["Trees"])
     player.anim:draw(player.spriteSheet, player.x, player.y, nil, 6, nil, 6, 9)
     myNPC:draw()
 
         if nearbyNPC then
             drawInteractPrompt(nearbyNPC)
         end
     cam:detach()
 
     love.graphics.print("x = " .. math.floor(player.x) .. " y = " .. math.floor(player.y), 10, 10)
 
     local tx = math.floor(player.x / gameMap.tilewidth) + 1
     local ty = math.floor((player.y + 50) / gameMap.tileheight) + 1
     local row = gameMap.layers["Trees"].data[ty]
     local t = row and row[tx]
     love.graphics.print("tile " .. tx .. "," .. ty .. " gid " .. tostring(t and t.gid), 10, 30)
 
     -- Dialogue UI is drawn last so it sits on top of everything.
     narrator:draw()

     if gameState == "gameover" then
        local w, h = love.graphics.getDimensions()
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 0, 0, w, h)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("GAME OVER", 0, h / 2 - 60, w / 3, "center", 0, 3, 3)
        love.graphics.printf("Press R to restart", 0, h / 2 + 20, w / 2, "center", 0, 2, 2)
    end
 end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    if gameState == "gameover" then
        if key == "r" then restartGame() end
        return
    end

    if narrator:isOpen() then
        -- Inside a dialog: advance / pick options.
        if key == "space" or key == "return" then
            narrator:onAction()
        elseif key == "up" then
            narrator:prevOption()
        elseif key == "down" then
            narrator:nextOption()
        end
    else
        -- Outside a dialog: E starts a conversation with the closest NPC.
        if key == "e" then
            narrator:startScript(myNPC)
        end
    end
end

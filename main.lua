function love.load()
    camera = require 'libraries/camera'
    NPC = require 'libraries/npc'
    anim8 = require 'libraries/anim8'
    sti = require 'libraries/sti'
    narrator = require 'libraries/narrator'

    cam = camera()
    cam:zoomTo(0.5)

    love.graphics.setDefaultFilter("nearest", "nearest")

    gameMap = sti('maps/forestEntrance.lua')

    player = {}
    player.x = 400
    player.y = 200
    player.speed = 5
    player.spriteSheet = love.graphics.newImage('sprites/player-sheet.png')
    player.grid = anim8.newGrid( 12, 18, player.spriteSheet:getWidth(), player.spriteSheet:getHeight() )

    player.animations = {}
    player.animations.down = anim8.newAnimation( player.grid('1-4', 1), 0.2 )
    player.animations.left = anim8.newAnimation( player.grid('1-4', 2), 0.2 )
    player.animations.right = anim8.newAnimation( player.grid('1-4', 3), 0.2 )
    player.animations.up = anim8.newAnimation( player.grid('1-4', 4), 0.2 )

    player.anim = player.animations.left

    -- character sheet, starting position, wander x, wander y
    myNPC = NPC.new('sprites/player-sheet.png', player.x + 100, player.y, 0, 0)

    -- Narrator: ink + talkies wrapper. See narrator.lua.
    narrator:init()

   characterFriend = narrator:newCharacter("Best Friend", nil)
   narrator:bindNPC(myNPC, characterFriend, "opening")

    -- Distance (in world pixels) at which the "E" prompt appears.
    interactRange = 200

    -- Set when the player is close enough to a bound NPC to interact.
    nearbyNPC = nil

    -- Font for the floating "E" key prompt.
    promptFont = love.graphics.newFont(14)
end

-- Check if a world position collides with a tile on the Trees layer
function treeAt(x, y)
    local layer = gameMap.layers["Trees"]
    local tx = math.floor(x / gameMap.tilewidth) + 1
    local ty = math.floor(y / gameMap.tileheight) + 1
    return layer.data[ty] and layer.data[ty][tx]
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
        --if treeAt(player.x, oldY) then player.x = oldX end
        --if treeAt(player.x, player.y) then player.y = oldY end

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
    -- First, get width/height of the game window
    local w, h = love.graphics.getDimensions()

    -- Get the size of the map in pixels
    local mapW = gameMap.width * gameMap.tilewidth
    local mapH = gameMap.height * gameMap.tileheight

    -- Keep the camera inside the map
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

    -- Dialogue UI is drawn last so it sits on top of everything.
    narrator:draw()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
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

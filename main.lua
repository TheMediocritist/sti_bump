local sti = require 'libs/sti'
local bump = require 'libs/bump/bump'
local scale = 2 -- set this to 1 and edit window size in conf.lua for Playdate scale

local gravity = 500

local player = {}
    player.facing = 'right'
    player.states = {grounded = 'on the ground',
                    jumping = 'jumping',
                    falling = 'falling'}
    player.x = 20
    player.y = 50
    player.w = 10
    player.h = 12
    player.yvel = 0
    player.xvel = 0
    player.xAcc = 500
    player.xVelMax = 100
    player.xVelFloor = 5    -- if velocity falls below this value, set vel to zero
    player.yVelMax = 100
    player.friction = 200
    player.jumpVel = 300

local world = bump.newWorld(20)

function love.load()
    -- load tilemap with STI
    map = sti('assets/maps/demo2.lua', {'bump'})
    -- create a bump world
    map:bump_init(world)
    -- add player to the bump world
    world:add(player, player.x, player.y, player.w, player.h)
end

function love.update(dt)
    map:update(dt)
    playerUpdate(dt)

end

function love.draw(dt)
    -- this prints some debug stuff to screen. Comment out to remove
    love.graphics.print('Player is: ' .. player.currentState, 0, 0)
    love.graphics.print('x, y: ' .. math.floor(player.x) .. ', ' .. math.floor(player.y) , 0, 10)
    love.graphics.print('xvel, yvel: ' .. math.floor(player.xvel * 10)/10 .. ', ' ..math.floor(player.yvel * 10)/10, 0, 20)
    love.graphics.print('dt / fps: ' .. printdt .. ' / ' .. math.floor(1/printdt), 0, 30 )
    
    -- Use these to make the level scroll (camera follows player)
    -- dx = player.x - (love.graphics.getWidth() / 2) / scale
    -- dy = player.y - (love.graphics.getHeight() / 2) / scale
    
    -- Use these for a fixed camera view (no scrolling)
    dx = 0
    dy = 0
    
    love.graphics.scale(scale)
    love.graphics.translate(-dx, -dy)

    map:draw(-dx, -dy, scale, scale)

    love.graphics.rectangle('fill', math.floor(player.x), math.floor(player.y), player.w, player.h)
end

function playerUpdate(dt)
    -- this is just a pointer to dt for the debug overlay
    printdt = math.floor(dt * 1000)/1000
    
    -- store the current player x & y position in case collision prevents movement
    player.lastX, player.lastY = player.x, player.y
    
    -- add or subtract from x velocity if left of right is pressed
    if love.keyboard.isDown('left') then
        player.facing = 'left'
        player.xvel = player.xvel - player.xAcc * dt
    end
    if love.keyboard.isDown('right') then
        player.facing = 'right'
        player.xvel = player.xvel + player.xAcc * dt
    end
    
    -- slows the player down if l/r isn't pressed, then when velocity is very small, stops movement
    -- a player.friction value of 100 removes 100 pixels of velocity per second
    if player.xvel > 0 then
        if player.xvel > player.xVelMax then player.xvel = player.xVelMax end
        if player.currentState == player.states['grounded'] then
            player.xvel = player.xvel - player.friction * dt
        end
    elseif player.xvel < 0 then 
        if player.xvel < -player.xVelMax then player.xvel = -player.xVelMax end
        if player.currentState == player.states['grounded'] then
            player.xvel = player.xvel + player.friction * dt
        end
    end
    if player.xvel < player.xVelFloor and player.xvel > -player.xVelFloor then 
        player.xvel = 0
    end

    -- apply gravity
    player.yvel = player.yvel + gravity * dt
    
    -- jump if up key pressed while player is grounded
    if love.keyboard.isDown('up') and player.currentState == player.states['grounded'] then
        player.currentState = player.states['jumping']
        player.yvel = player.yvel - player.jumpVel
    end
    
    -- distinguish between jumping and falling states - might be useful for animation or something
    if player.yvel > 0 then
        player.currentState = player.states['falling']
    elseif player.yvel < 0 then
        player.currentState = player.states['jumping']
    end
    
    -- player.dx and dy are the offsets between old and new player coordinates, fed into the collision check below
    player.dx = player.xvel * dt
    player.dy = player.yvel * dt
    
    -- check for collisions between the player and other world objects
    player.x, player.y, cols, len = world:move(player, player.x + player.dx, player.y + player.dy)
    
    for i,v in ipairs (cols) do
      -- turn the normals into collision directions 
      if cols[i].normal.x == -1 then side = 'right'
      elseif cols[i].normal.x == 1 then side = 'left'
      elseif cols[i].normal.y == 1 then side = 'above'
      elseif cols[i].normal.y == -1 then side = 'below'
      end
      
      if side == 'right' or side == 'left' then
          player.xvel = 0
      end
      
      if side == 'below' then
          player.currentState = player.states['grounded']
          player.yvel = 0
      end
      
      if side == 'above' then
          player.currentState = player.states['falling']
          player.yvel = 10
      end
    end

end
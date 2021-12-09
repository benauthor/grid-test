--   . . . . . . . . 
--   . . . . . . . .  GRID 
--   . . . . . . . .  TEST
--   . . . . . . . . 
--   . . . . . . . .   
--   . . . . . . . . 
--   . . . . . . . .   v0.1.5
--   . . . . . . . . 




-- GRID TEST 0.1.5
-- @okyeron
-- 
-- 

--  K2 : 2 second press + release = all leds on
--  K2 : Short press + release = all leds off - or cancel pattern
-- 
--  K3 : Fire Test Pattern

--  E3 : Select Test Pattern
--     Fade - brightness fade up from left to right
--     Chase - all leds on level 1, bright led travels across each row in order
--     Diagonal - diagonal pattern from top left to bottom right, fading over 6 steps
--     Random - random pattern - 10 times


local dp = 0
local cp = 0
local rp = 0
local down_time = 0
local glevel = 15
local devicepos = 1
local rotationpos = 0

local focus = { x = 0, y = 0, z = 0 }
local tiltvals = { x = 0, y = 0, z = 0 }

local pixels = {}
local patterns = {"fade", "chase", "diagonal", "random"}
local selectedpattern = 1
local grid_device
local grid_w
local grid_h
local tiltEnable = false

-- init function
function init()
  local grds = {}

  connect()
  print ("grid " .. grid.vports[devicepos].name.." "..grid_w .."x"..grid_h)
  grid_device:rotation(0)

  grid_device:tilt_enable(0,tiltEnable and 1 or 0) -- sensor number	0-7, 1 = on , 


  -- Get a list of grid devices
  for id,device in pairs(grid.vports) do
    grds[id] = device.name
  end
  
  -- setup params
  
  params:add{type = "option", id = "grid_device", name = "Grid", options = grds , default = 1,
    action = function(value)
      grid_device:all(0)
      grid_device:refresh()
      grid_device.key = nil
      grid_device = grid.connect(value)
      grid_device.key = grid_key
      grid_device.tilt = grid_tilt
      grid_dirty = true
      grid_w = grid_device.cols
      grid_h = grid_device.rows
      devicepos = value
      for i = 1, grid_w*grid_h do
        pixels[i] = 0
      end
      grid_device:tilt_enable(0,tiltEnable and 1 or 0)
      print ("grid selected " .. grid.vports[devicepos].name.." "..grid_w .."x"..grid_h)
    end}
    
  params:add{type = "option", id = "rotation", name = "Rotation", options = {"0","90","180","270"}, default = 1,
    action = function(value) 
        grid_device:rotation(value-1)
        rotationpos = value 
        grid_w = grid_device.cols
        grid_h = grid_device.rows
        print ("grid " .. grid.vports[devicepos].name.." "..grid_w .."x"..grid_h)
       for i = 1, grid_w*grid_h do
          pixels[i] = 0
        end
    end}

  params:add{type = "option", id = "tilt", name = "Tilt Enable", options = {"off","on"}, default = 1,
    action = function(value) 
        grid_device:tilt_enable(0,value-1)
        if (value == 2) then tiltEnable = true else tiltEnable = false end
    end}

  -- setup pixel array for oled
  -- for i = 1, grid_w*grid_h do
  --   pixels[i] = 0;
  -- end
    
  setup_metros()
end

function connect()
  grid_device = grid.connect(devicepos)
  grid_device.key = grid_key
  grid_device.tilt = grid_tilt
  grid_device.add = on_grid_add
  grid_device.remove = on_grid_remove
  grid_device:rotation(rotationpos)
  grid_w = grid_device.cols
  grid_h = grid_device.rows
  for i = 1, grid_w*grid_h do
    pixels[i] = 0;
  end

end

function setup_metros()
  -- digonal pattern metro
  dpattern = metro.init()
  dpattern.count = 40
  dpattern.time = 0.1
  dpattern.event = function(stage)
    dp = dp + 1
    diagonalpattern()
    gridfrompixels()
    redraw()
  end

  -- chase pattern metro
  cpattern = metro.init()
  cpattern.count = (grid_w * grid_h) + 1
  cpattern.time = 0.05
  cpattern.event = function(stage)
    cp = cp + 1
    chasepattern()
    if cp == cpattern.count then
      allledsoff()
    end
    redraw()
  end

  -- random pattern metro
  rpattern = metro.init()
  rpattern.count = 10
  rpattern.time = 0.5
  rpattern.event = function(stage)
    rp = rp + 1
    randompattern()
    redraw()
  end
  
end

function on_grid_add(g)
  print('on_add')
end

function on_grid_remove(g)
  print('on_remove')
end


function allledson()
  grid_device:all(15)
end
function allledsoff()
  grid_device:all(0)
    for i = 1, grid_w*grid_h do
      pixels[i] = 0;
    end
end

function chasepattern()
  for x = 1, grid_w do
    for y = 1, grid_h do
      yoffset = y-1
      pidx = x + (yoffset * grid_w)
      if cp == pidx then
        grid_device:led(x, y, 15)
        pixels[pidx]=15
        --draw_pixel(x,y,15)
      else
        grid_device:led(x, y, 1)
        pixels[pidx]=0
        --draw_pixel(x,y,0)

      end
    end
  end 
  
end

function randompattern()
  for x = 1, grid_w do
    for y = 1, grid_h do
      yoffset = y-1
      pidx = x + (yoffset * grid_w)
        brightness = math.random(0,15)
        grid_device:led(x, y, brightness)
        pixels[pidx]=brightness
    end
  end 
end


function fadepattern()
  for y = 1, grid_h do
    for x = 1, grid_w do
      yoffset = y-1
      pidx = x + (yoffset * grid_w)
      brightness = math.tointeger(x/grid_w * 16) - 1

      grid_device:led(x, y, brightness)
      pixels[pidx] = brightness
    end
  end 
end

function diagonalpattern()
  local dimval = 0
  for x = 1, grid_w do
    for y = 1, grid_h do
      yoffset = y-1
      pidx = x + (yoffset * grid_w)

      if dp == x+y then
        grid_device:led(x, y, glevel)
        pixels[pidx]=15
      elseif dp - 1 == x+y then
        grid_device:led(x, y, glevel-2)
        pixels[pidx]=glevel-2
      elseif dp - 2 == x+y then
        grid_device:led(x, y, glevel-4)
        pixels[pidx]=glevel-4
      elseif dp - 3 == x+y then
        grid_device:led(x, y, glevel-6)
        pixels[pidx]=glevel-6
      elseif dp - 4 == x+y then
        grid_device:led(x, y, glevel-8)
        pixels[pidx]=glevel-8
      elseif dp - 5 == x+y then
        grid_device:led(x, y, glevel-10)
        pixels[pidx]=glevel-10
      elseif dp - 6 == x+y then
        grid_device:led(x, y, glevel-12)
        pixels[pidx]=glevel-12
      else 
        grid_device:led(x, y, dimval)
        pixels[pidx]=0
      end
    end 
  end 
end
  
function gridredraw()
  grid_device:refresh()
end 

function gridfrompixels()
  for x = 1, grid_w do
    for y = 1, grid_h do
      yoffset = y-1
      pidx = x + (yoffset * grid_w)
      grid_device:led(x, y, pixels[pidx])
    end
  end 
end

function grid_tilt(sensor, x, y, z)
  if (x == nil) then x=0 end
  tiltvals.x = x
  if (y == nil) then y=0 end
  tiltvals.y = y
  if (z == nil) then z=0 end
  tiltvals.z = z
  redraw()
end

function grid_key(x, y, z)
  focus.x = x
  focus.y = y
  focus.z = z
  yoffset = y-1
  pidx = x + (yoffset * grid_w)
  
  local grid_h = grid_h
  if z > 0 then
    if pixels[pidx]>0 then
      grid_device:led(x, y, 0)
      pixels[pidx]=0

    else 
      grid_device:led(x, y, 15)
      pixels[pidx]=15

    end 
  end
  redraw()
end

function stopallpatterns()
    cpattern:stop()
    dpattern:stop()
    rpattern:stop()
end

-- encoder function
function enc(n, delta)
  if n == 3 then
    selectedpattern = util.clamp (selectedpattern + delta, 1, #patterns)
  end
  -- redraw screen
  redraw()
end

-- key function
function key(n, z)
  if n==1 then

  end
  
  if n==2 then
    if z == 1 then
      down_time = util.time()
    else
      stopallpatterns()
      hold_time = util.time() - down_time
      if hold_time < 1 then
        allledsoff()
        print("all leds off")
      elseif hold_time > 1 then
        allledson()
        print("all leds on")
      end
    end
  end 
  if n==3 and z==1 then
    stopallpatterns()
    dp = 0
    cp = 0
    rp = 0
    
    if selectedpattern == 1 then
      fadepattern()
    elseif selectedpattern == 2 then
      cpattern:start()
    elseif selectedpattern == 3 then
      dpattern:start()
    elseif selectedpattern == 4 then
      rpattern:start()
    end
  end 
  
  -- redraw screen
  redraw()
end


function draw_pixel(x,y,b)
  yoffset = y-1
  pidx = x + (yoffset * grid_w)
  if pixels[pidx] > 0 then
  --if focus.x == x and focus.y == y then
    screen.stroke()
    screen.level(b)
  end
  screen.pixel((x*offset.spacing) + offset.x, (y*offset.spacing) + offset.y)
  if pixels[pidx] > 0 then
    screen.stroke()
    screen.level(1)
  end
end

function draw_grid()
  screen.level(1)
  offset = { x = 76, y = 2, spacing = 3 }
  for x=1,grid_w,1 do 
    for y=1,grid_h,1 do 
      yoffset = y-1
      pidx = x + (yoffset * grid_w)
      
      draw_pixel(x,y,pixels[pidx])
    end
  end
  screen.stroke()
end



-- screen redraw function
function redraw()
  local rdeg
 
   gridredraw()

 -- screen: turn on anti-alias
  --screen.aa(1)
  screen.line_width(1.0)
  -- clear screen
  screen.clear()
  
  
  -- set pixel brightness (0-15)
  screen.level(15)
  screen.move(0, 8)
  screen.text("GRID TEST")

  screen.move(0, 24)
  if rotationpos == 2 then rdeg = 90
  elseif rotationpos == 3 then  rdeg = 180
  elseif rotationpos == 4 then  rdeg = 270
  else rdeg = 0
  end

  screen.text("Rotation = " .. rdeg)

  screen.move(0, 33)
  screen.text("Pattern: ".. patterns[selectedpattern])

  if (tiltEnable) then
    screen.move(0, 42)
    screen.text("Tilt: "..tiltvals.x..", "..tiltvals.y..", "..tiltvals.z)
  end 
  
  screen.move(0, 51)
  screen.text("Grid Key: "..focus.x..", "..focus.y..", "..focus.z)


  screen.move(0, 60)
  screen.text(devicepos .. ": "..grid.vports[devicepos].name.." "..grid_w .."x"..grid_h)

  draw_grid()
  
  -- refresh screen
  screen.update()
end

-- called on script quit, release memory
function cleanup ()
  grid_device:tilt_enable(0,0) -- sensor 0, 0 = off
  grid_device:rotation(0)
end

-- cheerlights.lua
-- get the latest colour
-- Chris Dennis, 12/12/2015

print("this is cheerlights.lua")
local module = {}

local state = require('state')
local rgb = require('set-colour')

function randomhue ()
    return math.random(0, 359)
end

-- shared state
state.cl = {}
state.cl.colour = '' -- latest colour name
state.cl.hue = randomhue()

-- Official cheerlights colours
-- Colours are scaled 0-10,000 for easy integer arithmetic
local maxcol = 10000

-- Convert a hex colour string e.g. #ff00ff
-- to separate r,g,b values, scaled to maxcol
local function scalehex (hex)
    hex = hex:gsub('#', '')
    local r = tonumber('0x'..hex:sub(1,2))
    local g = tonumber('0x'..hex:sub(3,4))
    local b = tonumber('0x'..hex:sub(5,6))
    r = r * maxcol / 255
    g = g * maxcol / 255
    b = b * maxcol / 255
    return {r=r, g=g, b=b}
end

local cl = {
	--black     = scalehex('000000'),
	red       = scalehex('FF0000'),
    green     = scalehex('00FF00'),
    blue      = scalehex('0000FF'),
    cyan      = scalehex('00FFFF'),
    white     = scalehex('FFFFFF'),
    oldlace   = scalehex('FDF5E6'),
    warmwhite = scalehex('FDF5E6'),
    purple    = scalehex('800080'),
    magenta   = scalehex('FF00FF'),
    yellow    = scalehex('FFCC00'),
    orange    = scalehex('FF3300'),
    pink      = scalehex('FF69B4')
}

local timer1 = nil
local timer2 = nil
local timer = nil

-- HSL to RGB formula from www.rapidtables.com/convert/color/hsl-to-rgb.htm
-- saturation fixed at 100%
-- lightness  fixed at  50%
-- so these are constants:
-- C = (1 - abs(2*Li - 1)) * S   = 1.0000
-- m = L - C/2                   = 0.0000
-- so we can simplify things
-- hue 0..359
-- rgb, each 0..max
function hue2rgb (h, max) 
	h = h % 360
	local X = max - math.abs((h * max / 60) % (2 * max) - max)
	if h < 60 then
		return max, X, 0
	elseif h < 120 then
		return X, max, 0
	elseif h < 180 then
		return 0, max, X
	elseif h < 240 then
		return 0, X, max
	elseif h < 300 then
		return X, 0, max
	else
		return max, 0, X
	end
end
    
local function run_pattern2 ()
	--state.cl.hue = (state.cl.hue + math.random(-1,1) * 1) % 360
	local step = (math.random(0,1)>0) and -1 or 1 -- randomly pick -1 or +1
	state.cl.hue = (state.cl.hue + step) % 360
	local r, g, b = hue2rgb(state.cl.hue, maxcol)
	--print("rp2, hue=", state.cl.hue, "  rgb=", r, g, b)
	rgb.setrgb(r, g, b)
    tmr.alarm(timer, 1000, 0, run_pattern2)
end

-- fade back to current hue and start the pattern
local function start_run_pattern2 ()
	print('starting at hue', state.cl.hue)
	local r, g, b = hue2rgb(state.cl.hue, maxcol)
	rgb.fadergb(r, g, b, 3000)
    tmr.alarm(timer, 3000, 0, run_pattern2)  -- delay till after fade complete
end

function module.set_colour (colour) 
	if colour ~= state.cl.colour and cl[colour] then
		tmr.stop(timer)  -- stop run_pattern2
		print ('setting new colour ' .. colour)
		rgb.fadergb(cl[colour].r, cl[colour].g, cl[colour].b)
		--rgb.setrgb(cl[colour].r, cl[colour].g, cl[colour].b)
		state.cl.colour = colour
		-- set timer in case we get bored
		tmr.alarm(timer, 5*60*1000, 0, start_run_pattern2)
	else
		print ('same/invalid colour, no change')
	end
end

function module.start (t)
    timer = t
    --module.run_pattern()
    start_run_pattern2()
end

return module

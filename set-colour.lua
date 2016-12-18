-- Set the colour via pwms 

print("this is set-colour.lua")

local module = {}

local state = require('state')
state.rgb = {}

local redpin = 1
local grnpin = 2
local blupin = 8	-- 5 is strange too	-- 3 goes high too often
-- 9 and 10 are rx/tx -- flicker when uploading files
-- and prevent diagnostics!

-- current colour (values up to maxcol)
state.rgb.red = 0
state.rgb.grn = 0
state.rgb.blu = 0
-- and in pwm range:
--state.rgb.redpwm = 0
--state.rgb.grnpwm = 0
--state.rgb.blupwm = 0

local maxpwm = 1023    -- hardware limit
local maxcol = 10000   -- same as in cheerlights.lua
-- TODO rename stdrgb
local stdrgb = 10000 -- 3000   -- up to maxcol, to limit overall brightness
							-- if it's more than maxcol, then errors will occur
-- adjustment factors -- just guessing so far
-- NB max is 1000 -- anything bigger could cause an error 
local redadj = 1000
local grnadj = 600
local bluadj = 900

local timer = nil

function module.start (t)
    timer = t
    -- initialise to off, 200Hz.  try 1000
    pwm.setup(redpin, 1000, 0)
    pwm.setup(grnpin, 1000, 0)
    pwm.setup(blupin, 1000, 0)
    pwm.start(redpin)
    pwm.start(grnpin)
    pwm.start(blupin)
end

-- bring a colour into range for pwm
function pwmrange (r, g, b)
    if r < 0 then r = 0 end
    if g < 0 then g = 0 end
    if b < 0 then b = 0 end
    if r > maxcol then r = maxcol end
    if g > maxcol then g = maxcol end
    if b > maxcol then b = maxcol end
	-- allow for colour bias in hardware
	r = r * redadj / 1000
	g = g * grnadj / 1000
	b = b * bluadj / 1000
	--print("adjusted: r,g,b:", r, g, b)
    -- adjust overall level to always be stdrgb
    rgb = r + g + b
	if rgb == 0 then
		-- black!
		return 0,0,0
	end
	r = r * stdrgb / rgb
	g = g * stdrgb / rgb
	b = b * stdrgb / rgb
	-- r+g+b now == stdrgb, so each is <=stdrgb
    --print("pwmrange hue=", state.cl.hue, " rgb=", rgb, " r g b: ", r, g, b)
    return r * maxpwm / maxcol, 
           g * maxpwm / maxcol, 
           b * maxpwm / maxcol
end

-- Set a colour -- values should be in the range 0--maxcol
-- (although it's their relative values that are important)
function module.setrgb (r, g, b)
    -- only if fadesteps is small  :
	--print("setting rgb to (raw)", r, g, b)
    -- note current colour (up to maxcol)
    state.rgb.red, state.rgb.grn, state.rgb.blu = r, g, b
    r, g, b = pwmrange(r, g, b)
    --state.rgb.redpwm, state.rgb.grnpwm, state.rgb.blupwm = r, g, b
    --print("setting rgb to (pwm)", r, g, b)
	if r > maxpwm or g > maxpwm or b > maxpwm then
		--print("!!! value out of range: r,g,b=", r, g, b)
	else
		pwm.setduty(redpin, r)
		pwm.setduty(grnpin, g)
		pwm.setduty(blupin, b)
	end
end

-- fade from old colour to new
-- in the range 0..maxcol
local fadetime = 3000   
local fadesteps = 50
local fadestep = 0 
local startred, startgrn, startblu = 0, 0, 0
local targetred, targetgrn, targetblu = 0, 0, 0
local function fader ()
    fadestep = fadestep + 1
    if fadestep >= fadesteps then
        tmr.stop(timer)
        -- make sure we get exactly to the target
		--print("last step from", state.rgb.red, state.rgb.grn, state.rgb.blu, "to", targetred, targetgrn, targetblu)
        module.setrgb(targetred, targetgrn, targetblu)
        --print("finished fading")
    else
        --print("step", fadestep)
		local stepred = (targetred - startred) * fadestep / fadesteps
		local stepgrn = (targetgrn - startgrn) * fadestep / fadesteps
		local stepblu = (targetblu - startblu) * fadestep / fadesteps
		--if fadestep == 1 then
		--	print("step by ", fadestep, stepred, stepgrn, stepblu)
		--end
        module.setrgb(
            startred + stepred,
            startgrn + stepgrn,
            startblu + stepblu
        )
    end
end
function module.fadergb (r, g, b, time, steps)
    tmr.stop(timer) -- in case a fade is already active
    fadetime = time or 3000
    fadesteps = steps or 50
    if (r == state.rgb.red and b == state.rgb.blu and g == state.rgb.grn) then
        --print("same colour, not fading")
        return
    end
    -- reset the target colour and then start the fade
    startred, startgrn, startblu = state.rgb.red, state.rgb.grn, state.rgb.blu
    targetred, targetgrn, targetblu = r, g, b
    fadestep = 0
    print("fading to", targetred, targetgrn, targetblu)
    --print("time, steps:", fadetime, fadesteps)
    tmr.alarm(timer,
              fadetime / fadesteps,
              1, fader)
end

return module

-- wifi setup module
-- with code adapted from foobarflies.io

print("This is wifi-setup-76awd.lua")

local state = require('state')
state.wifi = {}
state.wifi.ip = nil     -- non-nil if connected
state.wifi.ssid = nil   -- currently being tried or connected if ip
state.wifi.status = nil

local module = {}

local networks = require('wifi-ssids')
---- Known networks
---- Table is like this to allow random selection
--local networks = {
--    --{ ssid = 'XT1039 2850',     key = 'secret54321' },
--    { ssid = 'aa.net.uk 29739', key = 'ArryAardvark' },
--}

-- control the onboard led -- pass true for on, false for off
local obl_pin = 4
local function onboard_led (on)
    gpio.mode(obl_pin, gpio.OUTPUT)
    if on then
        gpio.write(obl_pin, gpio.LOW)
    else
        gpio.write(obl_pin, gpio.HIGH)
    end
end        

local timer1 = nil
local timer2 = nil

local wait_count = 0
local function wait_for_connection ()
    state.wifi.ip = wifi.sta.getip()
    if state.wifi.ip then
        tmr.stop(timer2)
        onboard_led(true)
        print("Connected to " .. state.wifi.ssid .. " with IP " .. state.wifi.ip)
    else
        if wait_count > 10 then
            print("Gave up waiting for IP")
            wait_count = 0
            tmr.stop(timer2)
        else 
            wait_count = wait_count + 1
            print("Waiting for IP, status is ", wifi.sta.status())
        end
    end
end

-- Pick a wifi network at random and connect to it
local function choose_ssid (ap_list)
    --print('#ap_list:', #ap_list)
    if (ap_list) then
        local network = networks[math.random(#networks)]
        if ap_list[network.ssid] then
            wifi.sta.config(network.ssid, network.key)
            wifi.sta.autoconnect(1)
            wifi.sta.connect()
            print("Connecting to '" .. network.ssid .. "'...")
            state.wifi.ssid = network.ssid
            tmr.alarm(timer2, 1000, 1, wait_for_connection)
        else 
            print("Network not available: " .. network.ssid)
        end
    else
        print("Couldn't get list of SSIDs")
    end
end

-- Establish and maintain a wifi connection
-- Called repeatedly via an alarm
function maintain_wifi ()
    if state.wifi.status == nil then
        state.wifi.status = 0 -- first time hack
    else
        state.wifi.status = wifi.sta.status()
    end
    if state.wifi.status == 5 then
        -- seems to be OK
        -- TODO check by pinging something?
        --print("wifi is OK, status is ", state.wifi.status)
    else
        -- No connection -- try to get one
        print("no wifi connection, status is ", status)
        onboard_led(false)
        state.wifi.ip = nil
        wifi.setmode(wifi.STATION)
        wifi.sta.getap(choose_ssid)
    end
    -- repeat ad nauseam
    tmr.alarm(timer1, 10000, 1, maintain_wifi)
end

function module.connect (t1, t2)
    timer1, timer2 = t1, t2
    print("Setting up wifi...")
    state.wifi = {}
    state.wifi.ip = nil
    wifi.setmode(wifi.STATION)
    wifi.sta.disconnect()
    maintain_wifi()
end

--module.connect(1,2) -- temp
return module

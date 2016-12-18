-- source-mqtt.lua
-- get the latest colour from mqtt
-- Chris Dennis, 12/12/2015

print('This is source-mqtt.lua')
local module = {}

local state = require('state')
local cheerlights = require('cheerlights')

-- MQTT client
local mc = nil

-- shared state
state.mqtt = {}
state.mqtt.connected = false
state.mqtt.unavailable = false

local timer = nil

local function setup_mqtt ()
	state.mqtt.connected = false
	state.mqtt.unavailable = false
    mc = mqtt.Client('cheerlights76awd', 120, '', '', 1)
end

local function mqtt_connect_ok (c) 
	print('mqtt connected')
	state.mqtt.connected = true
	c:subscribe('cheerlights', 0, function (c2) 
		print('mqtt subscribed cheerlights')
		-- needed?  state.mqtt.subscribed = true
	end)
    c:on('connect', function (c) 
        print('c:mqtt connect event')
        state.mqtt.connected = true  
    end)
    c:on('offline', function (c)
        print('c:mqtt offline event')
        state.mqtt.connected = false  -- ??
    end)
    c:on('message', function (c, topic, data)
        print("c:mqtt sent topic " .. topic)
        if data ~= nil then
            print("   and data " .. data)
			cheerlights.set_colour(data)
        end
    end)
end

local function mqtt_connect_failed (c, reason)
	print('mqtt connect failed, reason ', reason)
	if reason == -3 or
	   reason == -2 or
	   reason == -1 or
	   reason ==  0 or
	   reason ==  3 then
		-- keep trying
	else
		-- give up
		print('mqtt -- give up')
		c:close()
		state.mqtt.unavailable = true
	end
end

local function maintain_mqtt ()
	--print('mqtt connected? ', state.mqtt.connected)
	if state.wifi.ip then
		if state.mqtt.connected then
			-- OK
		else
			print('connecting to mqtt')
			local ok, err = pcall(function () 
				mc:connect('iot.eclipse.org', 1883, 
					0,  -- 1 for 'secure'
					1,  -- 1 to autoreconnect  
					mqtt_connect_ok, mqtt_connect_fail)
			end) 
			if not ok then
				if err == 'already connected' then
					state.mqtt.connected = true
				end
				print('error connecting: ', err)
			end
		end
	else
		-- no wifi, disconnect mqtt if necessary
		print('mqtt: no wifi, closing')
		if state.mqtt.connected then
			mc:close()
			state.mqtt.connected = false
		end
	end
	if not state.mqtt.unavailable then
		tmr.alarm(timer, 10000, 0, maintain_mqtt)	
	end
end

function module.start (t)
    timer = t
	setup_mqtt()
    maintain_mqtt()
end

return module

-- source-http.lua
-- get the latest colour from http
-- Chris Dennis, 9/12/2016

print('This is source-http.lua')
local module = {}

local cheerlights = require('cheerlights')
local state = require('state')
--local http = require('http')

local function get_reply (status, body)
	print('http reply: ', status, body)
	if status == 200 then
		cheerlights.set_colour(body)
	end
end

local function poll ()
	if state.wifi.ip then
		http.get("http://api.thingspeak.com/channels/1417/field/1/last.txt", nil, get_reply)
	end
end

function module.start (timer)
	tmr.alarm(timer, 10000, 1, poll)	
end

return module

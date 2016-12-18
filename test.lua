-- test|init.lua of cheerlights1

--uart.setup(0,115200,8,0,1)

print("This is test.lua")

-- Make these global to allow manual interaction
-- (but don't override existing globals e.g. MQTT)
State = require("state")
WiFi  = require("wifi-setup-76awd")
CLMQTT = require("source-mqtt")
CLHTTP = require("source-http")
CL    = require("cheerlights")
RGB   = require("set-colour")

-- Avoid timer conflicts by passing unique timer ids
-- The order of these is important
RGB.start(0)
WiFi.connect(1, 2)
CL.start(3)
CLMQTT.start(4)
CLHTTP.start(5)

print("End of test.lua")

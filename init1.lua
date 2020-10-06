sw0 = 0
sw1 = 1
sw2 = 2
sw3 = 3
led = 4
--sw4 = 4
sw5 = 5
sw6 = 6
sw7 = 7
sw8 = 8

gpio.mode(led, gpio.OUTPUT)
gpio.write(led, gpio.LOW)  -- ON

gpio.mode(sw0, gpio.OUTPUT)
gpio.mode(sw1, gpio.OUTPUT)
gpio.mode(sw2, gpio.OUTPUT)
-- gpio.mode(sw3, gpio.OUTPUT)
gpio.mode(sw3, gpio.INPUT, gpio.PULLUP)
-- gpio.mode(sw4, gpio.OUTPUT)
-- gpio.mode(sw5, gpio.INPUT, gpio.PULLUP)
-- gpio.mode(sw6, gpio.INPUT, gpio.PULLUP)
gpio.mode(sw5, gpio.OUTPUT)
gpio.mode(sw6, gpio.OUTPUT)
gpio.mode(sw7, gpio.OUTPUT)
gpio.mode(sw7, gpio.OUTPUT)

gpio.write(sw0, gpio.LOW)
gpio.write(sw1, gpio.LOW)
gpio.write(sw2, gpio.LOW)
gpio.write(sw3, gpio.LOW)
-- gpio.write(sw4, gpio.LOW)
gpio.write(sw5, gpio.LOW)
gpio.write(sw6, gpio.LOW)
gpio.write(sw7, gpio.LOW)
gpio.write(sw8, gpio.LOW)

qq = "SuperMan"

ssid0 = "AlaniPhone"
pswd0 = "aa76543210"
mqtt_server = nil
-- wifi_had_set = 0
if file.exists("device.cfg") then  -- file exist
    cfg = file.open("device.cfg", "r")
    ssid0      = cfg:readline()   -- SSID
    ssid0      = ssid0:gsub("\n", "")
    pswd0      = cfg:readline()   -- password
    pswd0      = pswd0:gsub("\n", "")
    mqtt_server       = cfg:readline()   -- password
    mqtt_server       = mqtt_server:gsub("\n", "")
    cfg.close()
    -- wifi_had_set = 1
    print("rd-SSID=" .. ssid0 .. ", Pswd=" .. pswd0)
end
if (mqtt_server == nil) then mqtt_server = "aaa.homeyes.com.tw" end
report_url = "http://"..mqtt_server.."/device/report.php"

----------------------------------
mac0 = wifi.ap.getmac() -- 11:22:33:00:11:22
mac  = ""
for i = 1, 16, 3 do mac = mac .. string.sub(mac0,i,i+1) end -- 112233001122

-- mac = string.sub(mac,1,2) .. string.sub(mac,4,5) .. string.sub(mac,7,8) .. string.sub(mac,10,11) .. string.sub(mac,13,14) .. string.sub(mac,16,17)
print("mac=" .. mac)
key = crypto.toHex(crypto.hash("md5", mac .. "*_mQ"))
key = string.sub(key,4,19)              
-- print("key:"..key)                   -- d580905eff93df0c
key_text = crypto.toHex(crypto.encrypt("AES-ECB", key, qq.." Go!!"))
qq = "2173"
key_text = string.sub(key_text,4,11)    
zz = "2fe1b"
-- print("key_text:"..key_text)         -- 6569a8de
key_text = tonumber(key_text, 16) % 100000000   
if (key_text < 10000000) then
    key_text = key_text+50000000        -- 51423326
end
-- print("mac=" .. mac)
ssidTemp=string.format("%s",string.sub(mac,7,12))

----------------------------------
--wifi.sta.config(key,config.SSID[key])
--wifi.sta.config{ssid=key,pwd=config.SSID[key]}

  wifi.ap.config({ssid="myWiFi_"..ssidTemp,pwd = "aa76543210"})
--wifi.ap.config("myWiFi_"..ssidTemp, "aa76543210")
cfg={}
cfg.ip="192.168.4.1"
cfg.netmask="255.255.255.0"
cfg.gateway="192.168.4.1"
wifi.ap.setip(cfg)

----------------------------------
--dhcp_config ={}
--dhcp_config.start = "192.168.4.100"
--wifi.ap.dhcp.config(dhcp_config)
wifi.ap.dhcp.start()

----------------------------------
--if (wifi_had_set == 1) then
    --start by setting both station and AP modes
    wifi.setmode(wifi.STATIONAP)
--else
--    wifi.setmode(wifi.SOFTAP)
--end

-- Print AP list that is easier to read
-- scan_wifi_str = ""
function listap(t)
--  scan_wifi_str = "<select id='ssid'>"
--  local i = 0
--  for ssid1,v in pairs(t) do
--      scan_wifi_str = scan_wifi_str .. "<option value='" .. ssid1 .."'"
--      if (ssid1 == ssid0) then
--          scan_wifi_str = scan_wifi_str .. " selected"
--      end
--      scan_wifi_str = scan_wifi_str .. ">" .. ssid1.."</option>"
--      i = i+1
--  end
--  scan_wifi_str = scan_wifi_str .. "</select>"
    gpio.write(led, gpio.HIGH)  -- OFF
--  print("WiFi Scan Done.")
end

tries = 0
function connect2Ap()
    --wifi.sta.config(ssid0,pswd0)

    wifi.sta.config({ssid=ssid0,pwd=pswd0})

    wifi.sta.connect()
    tries=20
    tmr.alarm(0, 50, 1, function()
        if (wifi.sta.getip() == nil) then
            tries = tries+1
            if (tries == 40) then 
                gpio.write(led, gpio.LOW)
                tries = 0
            else 
                gpio.write(led, gpio.HIGH) 
            end
        else
            print(mac .. " connected to AP, got ip: " .. wifi.sta.getip())
            tries = 9999    
            tmr.stop(0)
            wifi.sta.getap(listap)
        end
    end) 
end

tmr.alarm(0, 100, tmr.ALARM_AUTO, function(Q)  
    if wifi.ap.getip() == nil then
        tries=tries+1   --wait for AP to come up
    else
        tmr.stop(0)
        if (ssid0 ~= nil) then connect2Ap() end
    end
end)

-- Web Service
srv=net.createServer(net.TCP)
srv:listen(80,function(conn)
    conn:on("receive", function(client,request)

        local buf = "";
        local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
        if(method == nil)then
            _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
        end
        local _GET = {}
        if (vars ~= nil)then
--          for k, v in string.gmatch(vars, "(%w+)=([%w%._]+)&*") do
            for k, v in string.gmatch(vars, "(%w+)=([%w+-_.()^$#!~* %%]+)(&*)") do 
                _GET[k] = v
            end
        end

        if (_GET.wifi ~= nil and _GET.passwd ~= nil and _GET.server ~= nil) then
            ssid   = _GET.wifi:gsub(",", "")
            passwd = _GET.passwd:gsub(",", "")
            server = _GET.server

            if (string.len(passwd) < 8) then
                client:send("Password too short!")    
                client:close()
                return
            end

            dest = file.open("device.cfg", "w")
            dest:writeline(ssid)
            dest:writeline(passwd)
            dest:writeline(server)
            dest:close()

            print( "set SSID=" .. ssid .. ", Passwd=" .. passwd .. ", Server=" .. server)
            client:send("OK")    
            client:close()

            tmr.alarm(2, 2000, tmr.ALARM_SINGLE, function() 
                node.restart()
            end)
            return
        end
                
        if (_GET.led ~= nil) then
            if (_GET.led == "ON") then
                gpio.write(led, gpio.LOW)
            elseif (_GET.led == "OFF") then
                gpio.write(led, gpio.HIGH)
            end
        end
        
        buf = buf .. "<html><body align=center><h2>Switch: m" .. mac .. "</h2>"
        
        --red = " style='color:red'"
        --for i = 1,2 do
        --    buf = buf .. "<p>SW" .. i .. " <span " .. red .. ">"
        --    local sw = sw1
        --    if i == 2 then sw = sw2 end
        --    if (gpio.read(sw) == gpio.HIGH) then
        --        buf = buf .. "ON"
        --    else
        --        buf = buf .. "OFF"
        --    end
        --    buf = buf .. "</span></p>"
        --end

        --buf = buf .. "<p>LED <a href=\"?led=ON\"><button"
        --str = ">ON</button></a>&nbsp;<a href=\"?led=OFF\"><button"
        --if (gpio.read(led) == gpio.LOW) then
        --    buf = buf .. red .. str
        --else
        --    buf = buf .. str .. red
        --end
        --buf = buf .. ">OFF</button></a></p>"
        
        buf = buf .. "<script>function _set() {location.assign(\""
        buf = buf .. "?wifi=\"+document.getElementById('ssid').value.replace(/,/g,'')"    
        buf = buf .. "+\"&passwd=\"+document.getElementById('passwd').value.replace(/,/g,'')"
        buf = buf .. "+\"&server=\"+document.getElementById('server').value"
        buf = buf .. ");}</script>"
        
        buf = buf .. "<h2>Set WiFi - "
        if (ssid0 == nil) then 
            buf = buf .. "No AP Set!" 
        elseif (wifi.sta.getip() == nil) then 
            buf = buf .. "Disconnect" 
        else 
            buf = buf .. wifi.sta.getip() 
        end
        buf = buf .. "</h2><p>Select WiFi AP: <input type='text' size=24 id='ssid'"
        if (ssid0 ~= nil) then buf = buf .. " value='" .. ssid0 .. "'" end
        buf = buf .. "></p><p>Password: <input type='text' size=22 id='passwd'"
        --if (pswd ~= nil) then buf = buf .. " value='" .. pswd .. "'" end
        buf = buf .. "></p><p>Server: <input type='text' size=22 readonly id='server'"
        if (mqtt_server ~= nil) then buf = buf .. " value='" .. mqtt_server .. "'" end
        buf = buf .. ">&nbsp;&nbsp;<a href='javascript:_set();'><button>Set</button></a></p>"
        
        buf = buf .. "</body></html>"

        -- print( buf )
        
        client:send(buf)
        client:close()
        collectgarbage()
    end)
end)

print("MAC="..mac)
tmr.delay(1000000)
dofile("init2.lc")

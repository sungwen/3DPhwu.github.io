sw1 = 1
sw2 = 2
sw3 = 3
led = 4
-- sw4 = 4

----------------------------------
-- tsec, tusec, trate = rtctime.get()
-- math.randomseed( tsec )
-- ran = math.random(10001,99999)
-- print("tsec:" .. tsec .. ", ran:" .. ran)

----------------------------------
seq = 1532588043
offline = 1
send_cnt = -1
stflag = 1
ran = 128

function sendPkt(m)

    -----------------------
    -- ran = rtctime.get()
    m = m .. "," .. ran .. stflag
    ran = ran+1
    stflag = 0
    -- if (ran >= 99900) then ran = 10001 else ran = ran+1 end
    print("out:" .. m)

    m = encoder.toHex(crypto.encrypt("AES-ECB", key, m))
    url = report_url.."?mac=m" .. mac .. "&op=" .. m
    print("==>"..url)

    send_cnt = 0
    http.get(url, nil, function(code, data)
        if (code < 0) then
            print("HTTP request failed")
        else
            print(code .. " @ " .. data)
            gpio.write(led, gpio.LOW)
            tmr.alarm(2, 50, tmr.ALARM_SINGLE, function() 
                gpio.write(led, gpio.HIGH)
            end)
            if (code == 200) then 
                seq = tonumber(string.sub(data,4))

                --rtctime.set(seq, 0)
                --print(seq)
            end
        end
    end)            
end

function sendStatus()
    
    if (offline > 0) then return end

    op = "DEV"

    -----------------------
    for i = 0, 8, 1 do 
        if (gpio.read(i) == gpio.HIGH) then
            op = op .. ",1"
        else
            op = op .. ",0"
        end
    end

    sendPkt(op)
end

function sendEnter(m,t)

    if (offline > 0) then return end

    op = "RED," .. m .. "," .. string.format("%014d",t)
    sendPkt(op)
end

function showLED(r)
    r = 2*r
    tmr.alarm(6, 100, 1, function()
        if (r % 2 == 0) then gpio.write(led, gpio.LOW) 
        else gpio.write(led, gpio.HIGH) end
        r = r-1
        if (r <= 0) then tmr.stop(6) end
    end)
end     

---------------------------------------------
pin_TRIG = sw3
start_t  = 0
function pin_cb(level)
    --print("level-8:" .. level)

    if (offline == 0) then
        if (level == 0) then    -- blocked first !
            start_t = tmr.now()
            sendEnter(1,start_t)
            tmr.delay(50)
        else                    -- released 2nd !
            sendEnter(0,tmr.now()-start_t)
            tmr.delay(1000)
        end
        gpio.trig(pin_TRIG, "both", pin_cb)
    end
end

function startMontor()
    gpio.mode(pin_TRIG, gpio.INT)
    gpio.trig(pin_TRIG, "both", pin_cb)
end
function stopMontor()
    gpio.mode(pin_TRIG, gpio.INPUT)
end

---------------------------------------------
topic = "m" .. mac .. "/play/url"
-- send_cnt = -1
m = mqtt.Client("n" .. mac, 3600, "", "")   -- keepalive timer 3600s

m:on("connect", function(client)
    offline = 0 
    m:subscribe(topic, 2, function(conn) 
        print("subscribe success .. " .. wifi.sta.getip())
        print("MAC="..mac)

        sendStatus()
        startMontor()
        showLED(6)
    end)
end)

m:on("offline", function(client) 
    offline = 10    -- re-connect 10 seconds later
    stopMontor()
end)

turn_off = {}
turn_off[0] = 0
turn_off[1] = 0
turn_off[2] = 0
turn_off[3] = 0
turn_off[4] = 0
turn_off[5] = 0
turn_off[6] = 0
turn_off[7] = 0
turn_off[8] = 0

m:on("message", function(client, topic, data)
    offline = 0 
    if (data == nil) then return end

    local status, err = pcall(function () 
        cmd = encoder.fromBase64(data)       
        cmd = crypto.decrypt("AES-CBC", zz.."27f4a", cmd)
    end)
    if (cmd == nil) then return end

    s  = string.sub(cmd, 1, 10)
    sn = tonumber(s)
    if (sn-2 <= seq or seq == 1532588043) then
        -- print("err, old-seq")
        return
    end
    seq = sn
 
    local _aa = {}
    k = 0
    for v in string.gmatch(cmd, ":(%w+)") do
        _aa[k] = v
        k = k+1
    end
    if (tonumber(_aa[0]) ~= key_text) then
        --print("passwd err .. ")
        return
    end
        
    ------------------------------------
    -- for WiFi-Device -- 1:OFF:0
    ------------------------------------
    sw = tonumber(_aa[2])
--  if     (_aa[2] == "0") then sw = 0 
--  elseif (_aa[2] == "1") then sw = 1
--  elseif (_aa[2] == "2") then sw = 2
--  elseif (_aa[2] == "3") then sw = 3
--  elseif (_aa[2] == "5") then sw = 5
--  elseif (_aa[2] == "6") then sw = 6
--  elseif (_aa[2] == "7") then sw = 7
--  elseif (_aa[2] == "8") then sw = 8
    if (sw == 4 or sw > 8) then
        sendStatus()
        return 
    end
    
    print("D" .. sw .. "=" .. _aa[3])    
    if (_aa[3] == 'ON') then 
        gpio.write(sw, gpio.HIGH)
        if (_aa[4] ~= "0") then turn_off[sw] = tonumber(_aa[4]) end
    elseif (_aa[3] == "OFF") then
        gpio.write(sw, gpio.LOW)
    end
    sendStatus()
    gpio.write(led, gpio.LOW)
    tmr.alarm(2, 300, tmr.ALARM_SINGLE, function() 
        gpio.write(led, gpio.HIGH)
    end)
    ------------------------------------
end)

zz = zz.."8af716"
tmr.alarm(5, 1000, 1, function() 

    for i = 0,8 do
        if (turn_off[i] > 0) then
            turn_off[i] = turn_off[i]-1
            if (turn_off[i] == 0) then
                gpio.write(i, gpio.LOW)
                sendStatus()
            end
        end
    end
        
    if (offline > 0) then
        if (wifi.sta.status() == 5) then    -- 5: got_ip
                
            offline = offline-1
            if (offline == 0) then
                m:connect(mqtt_server, 41883, 0)
                --tmr.register(4, READING_INTERVAL, tmr.ALARM_AUTO, trigger)
            end
        elseif (tries == 9999) then
            connect2Ap()
        end
            
    else
        send_cnt = send_cnt+1
        if (send_cnt >= 300) then
            sendStatus()    -- alive
        end
    end
end)


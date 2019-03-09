-- 433 Mhz UDP Gateway
-- (c) 2019 Alexander Graf

-- config
WIFI_SSID = "SSID"
WIFI_PW = "Password"
GPIO_NR = 6
MAX_PENDING = 16
DEBUG = 1
IS_SETUP = 0

-- globals
sending = 0
pending = nil

function mysplit(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, tonumber(str))
        end
        return t
end

local function count_pending()
    local p = pending
    local c = 0
    
    while p do
       c = c + 1
       p = p.next
    end

    return c
end

function send_data()
    sending = 1

    if DEBUG then
        print("send_data (" .. count_pending() .. ")");
    end

    -- pop from the pending list
    local p = pending

    -- nothing pending
    if p == nil then
        return
    end
    
    pending = p.next
    local pl = p.value
    local s = mysplit(pl)
    pl = nil
    p = nil
    
    gpio.serout(GPIO_NR, gpio.HIGH, s, 1, function()
      gpio.write(GPIO_NR, gpio.LOW)
      if pending == nil then
          if DEBUG then
              print("send_data finished, end");
          end
          sending = 0
      else
          if DEBUG then
              print("send_data finished, more pending");
          end
          send_data()
      end
    end)
end

function new_data(srv, pl)
    --print("New Data: " .. pl .. "\n");
    if (string.find(pl, '\n')) then
        new_udp_data(srv, pl, nil, nil)
        srv:send("OK\n", function(srv)
            srv:close()
        end)
    end
end

function new_udp_data(srv, pl, port, ip)
    --print("New Data: "); print(pl);
    if DEBUG then
        print("new_data");
    end
    
    local p = pending
    if p == nil then
        pending = { value = pl, next = nil }
    elseif count_pending() < MAX_PENDING then
        while p do
          if p.next == nil then
            -- last entry, let's append
            p.next = { value = pl, next = nil }
            p = nil
          else
            p = p.next
          end
        end

    end

    if DEBUG then
        print("New pending: " .. count_pending())
    end

    if sending == 0 then
        send_data(pl)
    end
end

-- Initialize wifi

wifi.setmode(wifi.STATION)

-- Only need this once
if IS_SETUP then
    station_cfg={}
    station_cfg.ssid=WIFI_SSID
    station_cfg.pwd=WIFI_PW
    wifi.sta.config(station_cfg)
end

wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
    print("\nSTA - CONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..
    T.BSSID.."\n\tChannel: "..T.channel)
end)

wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
    print("\nSTA - GOT IP".."\n\tStation IP: "..T.IP.."\n\tSubnet mask: "..
    T.netmask.."\n\tGateway IP: "..T.gateway)
end)


-- Initialize GPIO
gpio.mode(GPIO_NR, gpio.OUTPUT)
gpio.write(GPIO_NR, gpio.LOW)

-- Set up TCP listener
--srv=net.createServer()
--srv:listen(1236, function(conn)
--    conn:on("receive", new_data)
--    conn:send("NodeMCU Blind Control\n")
--  end)

-- Set up UDP listener
udp=net.createUDPSocket()
udp:listen(1236)
udp:on("receive", new_udp_data)


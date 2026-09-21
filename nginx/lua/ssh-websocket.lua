-- Fixed SSH destination: authentication stays with the VM's SSH server.
local headers = ngx.req.get_headers()
if ngx.req.get_method() ~= "GET" or headers.origin
    or type(headers.upgrade) ~= "string"
    or string.lower(headers.upgrade) ~= "websocket" then
    return ngx.exit(400)
end

local upstream = ngx.socket.tcp()
upstream:settimeouts(5000, 60000, 60000)
local ok, err = upstream:connect("10.119.85.50", 22)
if not ok then
    ngx.log(ngx.ERR, "cashflow SSH connect failed: ", err)
    return ngx.exit(502)
end

local ws, handshake_err = require("resty.websocket.server"):new({
    timeout = 60000,
    max_payload_len = 65536,
})
if not ws then
    upstream:close()
    ngx.log(ngx.WARN, "SSH WebSocket handshake failed: ", handshake_err)
    return ngx.exit(400)
end

-- Serialize pong replies and SSH output on the downstream socket.
local lock = require("ngx.semaphore").new(1)
local function send(method, data)
    if not lock:wait(60) then return nil end
    local sent = method(ws, data)
    lock:post(1)
    return sent
end

local reader = ngx.thread.spawn(function()
    while true do
        local data, typ = ws:recv_frame()
        if not data then return end
        if typ == "binary" or typ == "continuation" then
            if not upstream:send(data) then return end
        elseif typ == "ping" then
            if not send(ws.send_pong, data) then return end
        elseif typ ~= "pong" then
            return
        end
    end
end)

local writer = ngx.thread.spawn(function()
    while true do
        local data = upstream:receiveany(32768)
        if not data or not send(ws.send_binary, data) then return end
    end
end)

ngx.thread.wait(reader, writer)
ngx.thread.kill(reader)
ngx.thread.kill(writer)
upstream:close()
ws:send_close()

if ngx.var.uri == "/api/traffic" then
    return
end

local cjson = require "cjson"

local log_data = {
    ip = ngx.var.remote_addr or "unknown",
    user_agent = ngx.var.http_user_agent or "unknown",
    domain = ngx.var.host or "unknown",
    path = ngx.var.uri or "/",
    method = ngx.var.request_method or "GET",
    referer = ngx.var.http_referer or "none",
    timestamp = math.floor(ngx.now() * 1000),
    request_time = (tonumber(ngx.var.request_time) or 0) * 1000,
    status = tonumber(ngx.var.status) or 0
}

local function post_traffic(premature, data)
    if premature then
        return
    end

    local http = require "resty.http"
    local httpc = http.new()
    httpc:set_timeout(1000)

    local res, err = httpc:request_uri("http://127.0.0.1:8501/api/traffic", {
        method = "POST",
        body = cjson.encode(data),
        headers = {
            ["Content-Type"] = "application/json",
            ["User-Agent"] = "Hanasand Traffic Logger 1.0",
        },
        ssl_verify = false,
    })

    if not res then
        ngx.log(ngx.DEBUG, "Traffic logger skipped: ", err)
    elseif res.status >= 400 then
        ngx.log(ngx.DEBUG, "Traffic logger upstream status ", res.status)
    end
end

local ok, err = ngx.timer.at(0, post_traffic, log_data)
if not ok then
    ngx.log(ngx.ERR, "Failed to schedule traffic logger: ", err)
end

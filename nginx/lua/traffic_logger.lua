if ngx.var.uri == "/api/traffic" then
    return
end

local http = require "resty.http"
local cjson = require "cjson"

local log_data = {
    ip = ngx.var.remote_addr or "unknown",
    user_agent = ngx.var.http_user_agent or "unknown",
    domain = ngx.var.host or "unknown",
    path = ngx.var.uri or "/",
    method = ngx.var.request_method or "GET",
    referer = ngx.var.http_referer or "none",
    timestamp = ngx.time()
}

ngx.log(ngx.ERR, "traffic logger fired host=", log_data.domain, " path=", log_data.path)

local httpc = http.new()
httpc:set_timeout(200)
local res, err = httpc:request_uri("http://127.0.0.1:8501/api/traffic", {
    method = "POST",
    body = cjson.encode(log_data),
    headers = {
        ["Content-Type"] = "application/json",
        ["User-Agent"] = "Hanasand Traffic Logger 1.0",
    },
    ssl_verify = false,
})

if not res then
    ngx.log(ngx.ERR, "Failed to post traffic: ", err)
elseif res.status >= 400 then
    ngx.log(ngx.ERR, "Traffic logger upstream status ", res.status, " body=", res.body or "")
end

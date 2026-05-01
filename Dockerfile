FROM openresty/openresty:alpine

RUN apk add --no-cache curl perl \
    && opm get ledgetech/lua-resty-http \
    && mkdir -p /var/log/nginx

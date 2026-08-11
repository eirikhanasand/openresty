FROM openresty/openresty:alpine

RUN apk add --no-cache curl perl python3 py3-pip openssl \
    && python3 -m venv /opt/certbot \
    && /opt/certbot/bin/pip install --no-cache-dir --upgrade pip \
    && /opt/certbot/bin/pip install --no-cache-dir certbot certbot-dns-domeneshop \
    && ln -s /opt/certbot/bin/certbot /usr/local/bin/certbot \
    && opm get ledgetech/lua-resty-http \
    && mkdir -p /var/log/nginx

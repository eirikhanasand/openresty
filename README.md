# Hanasand OpenResty

Dockerized OpenResty reverse proxy for `hanasand.com` and related services.

The service uses host networking so the existing upstreams such as `localhost:3000`, `localhost:8080`, and `localhost:8501` keep the same meaning they had in the host-level OpenResty service.

## Deploy

```sh
docker compose up -d --build
docker exec openresty openresty -t
curl -I https://hanasand.com
```

TLS certificates are read from `/etc/letsencrypt` on the host.

# Vane (formerly Perplexica) for Railway: the official all-in-one image (Vane + bundled SearXNG
# + headless Chromium for page scraping), with a small Caddy front door that adds a login.
# Bump both pins together with a CHANGELOG.md entry; a merge to main notifies every deployer.
FROM caddy:2.11.9@sha256:4851e54a46b206517c574821bb5cc67f170d2156041e9fbc4c9193b45e84a75b AS caddy

FROM itzcrazykns1337/vane:v1.12.2@sha256:61f2bbf3386ff3df08911fb3de0e1893b04702a4d49ef13fbadbda937b47ab7c

COPY --from=caddy /usr/bin/caddy /usr/bin/caddy
COPY Caddyfile /etc/caddy/Caddyfile
COPY start.sh /usr/local/bin/railway-start.sh
RUN chmod 755 /usr/local/bin/railway-start.sh && sed -i 's/\r$//' /usr/local/bin/railway-start.sh

# Vane and SearXNG listen on loopback only; Caddy is the only public listener ($PORT).
ENV SEARXNG_API_URL=http://127.0.0.1:8888 \
    PORT=8080

# Config (incl. provider API keys), chat history (SQLite) and uploads all live here.
VOLUME /home/vane/data
EXPOSE 8080

WORKDIR /home/vane
CMD ["/usr/local/bin/railway-start.sh"]

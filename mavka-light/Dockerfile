# Mavka Light — Telegram AI agent on a free cloud tier
# Optimized for Fly.io shared-cpu-1x@256MB
FROM node:22-alpine

# tini = proper PID 1 (so SIGTERM from Fly stops gracefully)
# tmux = optional, kept off here (we run pi in foreground)
# git = needed by pi to fetch its extensions on first run
RUN apk add --no-cache tini git curl python3 py3-pip ca-certificates

# Install Pi Coding Agent globally
RUN npm install -g @mariozechner/pi-coding-agent && \
    npm cache clean --force

# Optional: edge-tts for voice replies (small, ~5 MB)
# Pre-install so first message doesn't wait
RUN pip3 install --no-cache-dir --break-system-packages edge-tts || true

# App working directory + persistent memory volume mount point
WORKDIR /home/mavka
RUN adduser -D -h /home/mavka -s /bin/sh mavka && \
    mkdir -p /home/mavka/mavka-bot/memory/raw \
             /home/mavka/mavka-bot/memory/summaries \
             /home/mavka/mavka-bot/history \
             /home/mavka/mavka-bot/logs \
             /home/mavka/.pi/agent/extensions && \
    chown -R mavka:mavka /home/mavka

USER mavka

COPY --chown=mavka:mavka entrypoint.sh /home/mavka/entrypoint.sh
COPY --chown=mavka:mavka identity-template.md /home/mavka/identity-template.md
COPY --chown=mavka:mavka seed-memory/ /home/mavka/seed-memory/

RUN chmod +x /home/mavka/entrypoint.sh

# Fly.io volume will be mounted at /home/mavka/mavka-bot
# (memory and history survive deploys + restarts)
VOLUME ["/home/mavka/mavka-bot"]

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/home/mavka/entrypoint.sh"]

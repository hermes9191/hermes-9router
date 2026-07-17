# syntax=docker/dockerfile:1.7
# 9Router — Railway-optimized Dockerfile

ARG NODE_IMAGE=node:22-alpine
FROM ${NODE_IMAGE} AS base
WORKDIR /app

FROM base AS builder

# Build deps for node-forge / native modules
RUN apk --no-cache upgrade && \
    apk --no-cache add python3 make g++ linux-headers && \
    rm -rf /var/cache/apk/*

COPY package.json package-lock.json* ./
# حذف کامل قابلیت ماونت و استفاده از دستور استاندارد و ساده لینوکس
RUN npm install --omit=dev

COPY . ./
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

# ---- Runtime stage ----
FROM ${NODE_IMAGE} AS runner
WORKDIR /app

ENV NODE_ENV=production \
    HOSTNAME=0.0.0.0 \
    NEXT_TELEMETRY_DISABLED=1 \
    DATA_DIR=/app/data

# Copy built artifacts
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/custom-server.js ./custom-server.js
COPY --from=builder /app/open-sse ./open-sse
COPY --from=builder /app/src/mitm ./src/mitm
COPY --from=builder /app/node_modules/node-forge ./node_modules/node-forge
COPY --from=builder /app/node_modules/next ./node_modules/next

# Data directories
RUN mkdir -p /app/data /app/data-home && \
    chown -R node:node /app/data /app/data-home && \
    ln -sf /app/data-home /root/.9router 2>/dev/null || true

# Entrypoint: fix permissions on mounted volumes, then run
RUN apk --no-cache add su-exec && \
    printf '#!/bin/sh\nchown -R node:node /app/data /app/data-home 2>/dev/null\nexec su-exec node "$@"\n' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["node", "custom-server.js"]

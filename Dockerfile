# syntax=docker/dockerfile:1.7
# 9Router — GitHub Cloning & Railway Deployment Dockerfile

ARG NODE_IMAGE=node:22-alpine
FROM ${NODE_IMAGE} AS base
WORKDIR /app

FROM base AS builder

# ۱. نصب ابزارهای مورد نیاز برای دانلود و بیلد نیتیو پکیج‌ها
RUN apk update && apk upgrade && \
    apk add --no-cache git python3 make g++ linux-headers

# ۲. کلون کردن مستقیم کدهای اصلی پروژه ۹Router از سورس اصلی
RUN git clone https://github.com/decolua/9router.git .

# ۳. نصب وابستگی‌ها و بیلد پروژه Next.js
RUN npm install --omit=dev
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

# ---- Runtime stage ----
FROM ${NODE_IMAGE} AS runner
WORKDIR /app

ENV NODE_ENV=production \
    HOSTNAME=0.0.0.0 \
    NEXT_TELEMETRY_DISABLED=1 \
    DATA_DIR=/app/data

# کپی کردن تمام فایل‌های آماده شده از مرحله بیلد
COPY --from=builder /app ./

# تنظیم دایرکتوری‌های مربوط به دیتابیس و توکن‌ها و دسترسیNode
RUN mkdir -p /app/data /app/data-home && \
    chown -R node:node /app/data /app/data-home && \
    ln -sf /app/data-home /root/.9router 2>/dev/null || true

RUN apk add --no-cache su-exec && \
    printf '#!/bin/sh\nchown -R node:node /app/data /app/data-home 2>/dev/null\nexec su-exec node "$@"\n' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["node", "custom-server.js"]

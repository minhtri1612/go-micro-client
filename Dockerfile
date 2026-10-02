# Builder = host arch (Jenkins t4g arm64 / laptop amd64). Dist is JS, not arch-specific.
FROM --platform=$BUILDPLATFORM node:20-bullseye-slim AS builder
ARG BUILDARCH
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --no-audit --no-fund \
 && if [ "$BUILDARCH" = "arm64" ]; then \
      npm install --no-save --no-audit --no-fund \
        lightningcss-linux-arm64-gnu@1.30.1 \
        @tailwindcss/oxide-linux-arm64-gnu@4.1.14; \
    fi
COPY . .
ARG VITE_API_URL
ENV VITE_API_URL=$VITE_API_URL
RUN npm run build

# Final image follows docker build --platform (linux/amd64).
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

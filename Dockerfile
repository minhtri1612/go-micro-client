# Build stage (pin to stable LTS to avoid npm v10 issues)
FROM node:20-bullseye-slim AS builder

WORKDIR /app

    # Copy package files
COPY package*.json ./

# lockfile was generated on linux/amd64. Jenkins is t4g arm64, so npm ci
# skips lightningcss / @tailwindcss/oxide native addons for this platform.
RUN npm ci --no-audit --no-fund \
 && npm install --no-save --no-audit --no-fund \
      lightningcss-linux-arm64-gnu@1.30.1 \
      @tailwindcss/oxide-linux-arm64-gnu@4.1.14

# Copy source code
COPY . .

# Set build-time environment variables
ARG VITE_API_URL
ENV VITE_API_URL=$VITE_API_URL

# Build the application
RUN npm run build

# Production image is amd64 for Kind (t3). Builder may be arm64 on Jenkins t4g.
FROM --platform=linux/amd64 nginx:alpine

# Copy built assets from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]

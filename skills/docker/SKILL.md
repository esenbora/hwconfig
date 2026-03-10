---
name: docker
description: Use when containerizing apps, setting up dev environments, or deploying with containers. Dockerfile, docker-compose, multi-stage builds. Triggers on: docker, dockerfile, container, docker-compose, containerize, image, kubernetes, k8s, infrastructure, devops, prod deploy, production deploy.
version: 1.0.0
---

# Docker Deep Knowledge

> Multi-stage builds, optimization, compose, and production patterns.

---

## Quick Reference

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
CMD ["npm", "start"]
```

```bash
docker build -t myapp .
docker run -p 3000:3000 myapp
```

---

## Optimized Dockerfiles

### Multi-Stage Build (Node.js)

```dockerfile
# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies first (cache layer)
COPY package*.json ./
RUN npm ci

# Copy source and build
COPY . .
RUN npm run build

# Prune dev dependencies
RUN npm prune --production

# Production stage
FROM node:20-alpine AS runner

WORKDIR /app

# Don't run as root
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
USER nextjs

# Copy only production files
COPY --from=builder --chown=nextjs:nodejs /app/package*.json ./
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

CMD ["npm", "start"]
```

### Next.js Standalone Build

```dockerfile
FROM node:20-alpine AS base

FROM base AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED=1

RUN npm run build

FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy standalone output
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
```

### Python FastAPI

```dockerfile
# Build stage
FROM python:3.12-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Production stage
FROM python:3.12-slim AS runner

WORKDIR /app

# Copy virtual environment
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application
COPY . .

# Non-root user
RUN useradd --create-home --shell /bin/bash app
USER app

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## Layer Caching

### Optimal Order

```dockerfile
# 1. Base image (rarely changes)
FROM node:20-alpine

WORKDIR /app

# 2. System dependencies (rarely changes)
RUN apk add --no-cache libc6-compat

# 3. Package files (changes with deps)
COPY package.json package-lock.json ./

# 4. Install dependencies (cached if package files unchanged)
RUN npm ci

# 5. Copy source (changes frequently)
COPY . .

# 6. Build
RUN npm run build

CMD ["npm", "start"]
```

### .dockerignore

```
# Git
.git
.gitignore

# Dependencies
node_modules
.npm

# Build output
.next
dist
build

# Development
.env.local
.env*.local
*.log

# IDE
.vscode
.idea

# Testing
coverage
.nyc_output

# Docker
Dockerfile*
docker-compose*
.docker

# Documentation
README.md
docs
```

---

## Docker Compose

### Development Setup

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "3000:3000"
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgresql://postgres:password@db:5432/myapp
      - REDIS_URL=redis://redis:6379
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    command: npm run dev

  db:
    image: postgres:16-alpine
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=myapp
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

### Production Setup

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  app:
    image: myapp:${VERSION:-latest}
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/nginx/certs:ro
    depends_on:
      - app
```

---

## Image Optimization

### Reduce Image Size

```dockerfile
# Use slim/alpine base
FROM node:20-alpine  # ~140MB vs node:20 ~900MB
FROM python:3.12-slim  # ~150MB vs python:3.12 ~1GB

# Install only production deps
RUN npm ci --only=production

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN npm cache clean --force

# Use .dockerignore
# Don't copy unnecessary files
```

### Security Best Practices

```dockerfile
# Don't run as root
RUN addgroup --system app && adduser --system --group app
USER app

# Use specific versions
FROM node:20.10.0-alpine3.18

# Don't expose secrets
# Use --secret or build args
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) npm ci

# Scan for vulnerabilities
# docker scout cves myapp:latest
```

---

## Debugging

```bash
# Interactive shell
docker run -it myapp sh
docker exec -it container_name sh

# View logs
docker logs container_name
docker logs -f container_name  # Follow
docker logs --tail 100 container_name

# Inspect container
docker inspect container_name
docker inspect --format '{{.State.Status}}' container_name

# View resource usage
docker stats

# View processes
docker top container_name

# Copy files
docker cp container_name:/app/logs ./logs
docker cp ./config container_name:/app/config

# Build with progress
docker build --progress=plain -t myapp .
```

---

## Health Checks

```dockerfile
# HTTP health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Custom script
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD /app/healthcheck.sh

# Node.js healthcheck endpoint
# In your app:
app.get('/health', (req, res) => {
  // Check dependencies
  res.status(200).json({ status: 'healthy' });
});
```

---

## Networking

```yaml
# docker-compose.yml
services:
  app:
    networks:
      - frontend
      - backend
  
  db:
    networks:
      - backend

  nginx:
    networks:
      - frontend

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # No external access
```

---

## Common Commands

```bash
# Build
docker build -t myapp .
docker build -t myapp:v1.0 --no-cache .
docker build -f Dockerfile.prod -t myapp .

# Run
docker run -d -p 3000:3000 --name myapp myapp
docker run -d -p 3000:3000 -e NODE_ENV=production myapp
docker run -d -v $(pwd):/app myapp

# Manage
docker ps                    # Running containers
docker ps -a                 # All containers
docker stop container_name
docker rm container_name
docker rm -f container_name  # Force remove

# Images
docker images
docker rmi image_name
docker image prune -a        # Remove unused images

# Compose
docker compose up -d
docker compose down
docker compose logs -f
docker compose ps
docker compose exec app sh
docker compose build --no-cache

# Clean up
docker system prune -a       # Remove all unused data
docker volume prune          # Remove unused volumes
```

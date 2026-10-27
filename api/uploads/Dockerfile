# api/uploads. Build context = the repository root, so the image can copy
# the Kafka JSON Schemas from api/common/contract:
#   docker build -f api/uploads/Dockerfile .
# ---- deps ----
FROM node:24-slim AS deps
WORKDIR /app
COPY api/uploads/package*.json ./
RUN npm ci

# ---- builder ----
FROM node:24-slim AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY api/uploads/ ./
RUN npm run build

# ---- runtime ----
FROM node:24-slim AS runner
WORKDIR /app
ENV NODE_ENV=production CONTRACT_DIR=/app/contract
COPY api/uploads/package*.json ./
RUN npm ci --omit=dev
COPY --from=builder /app/dist ./dist
COPY api/common/contract/*.schema.json ./contract/
USER node
ENV PORT=8082
EXPOSE 8082
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:'+(process.env.PORT||8082)+'/health',r=>process.exit(r.statusCode<500?0:1)).on('error',()=>process.exit(1))"
CMD ["node", "dist/main.js"]

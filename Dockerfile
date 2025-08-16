# Use multi-stage build to create a lightweight production image
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci

FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ARG NEXT_PUBLIC_DEPLOYMENT_URL
ARG NEXT_PUBLIC_AGENT_ID
ARG NEXT_PUBLIC_LANGSMITH_API_KEY
ENV NODE_ENV=production \
    NEXT_PUBLIC_DEPLOYMENT_URL=${NEXT_PUBLIC_DEPLOYMENT_URL} \
    NEXT_PUBLIC_AGENT_ID=${NEXT_PUBLIC_AGENT_ID} \
    NEXT_PUBLIC_LANGSMITH_API_KEY=${NEXT_PUBLIC_LANGSMITH_API_KEY}
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
CMD ["npm", "start"]

FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
WORKDIR /app

# Copy package.json and package-lock.json
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Set NODE_ENV to production for optimal build
ENV NODE_ENV production

# Set environment variables for build
ARG MONGODB_URI
ARG NEXTAUTH_SECRET
ARG GEMINI_API_KEY
ARG CLIENT_ID
ARG CLIENT_SECRET
ARG REDIRECT_URI
ARG REFRESH_TOKEN
ARG EMAIL

ENV MONGODB_URI=$MONGODB_URI
ENV NEXTAUTH_SECRET=$NEXTAUTH_SECRET
ENV GEMINI_API_KEY=$GEMINI_API_KEY
ENV CLIENT_ID=$CLIENT_ID
ENV CLIENT_SECRET=$CLIENT_SECRET
ENV REDIRECT_URI=$REDIRECT_URI
ENV REFRESH_TOKEN=$REFRESH_TOKEN
ENV EMAIL=$EMAIL

# Build the application
RUN npm run build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

# Set environment variables for runtime
ARG MONGODB_URI
ARG NEXTAUTH_SECRET
ARG GEMINI_API_KEY
ARG CLIENT_ID
ARG CLIENT_SECRET
ARG REDIRECT_URI
ARG REFRESH_TOKEN
ARG EMAIL

ENV MONGODB_URI=$MONGODB_URI
ENV NEXTAUTH_SECRET=$NEXTAUTH_SECRET
ENV GEMINI_API_KEY=$GEMINI_API_KEY
ENV CLIENT_ID=$CLIENT_ID
ENV CLIENT_SECRET=$CLIENT_SECRET
ENV REDIRECT_URI=$REDIRECT_URI
ENV REFRESH_TOKEN=$REFRESH_TOKEN
ENV EMAIL=$EMAIL

# Create a non-root user to run the application
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
USER nextjs

# Copy the build output, node_modules, and public directory
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Set the command to run when the container starts
CMD ["node", "server.js"] 
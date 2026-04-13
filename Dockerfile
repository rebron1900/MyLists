# 构建阶段
FROM oven/bun:1-alpine AS builder

WORKDIR /app

# 复制依赖文件
COPY package.json ./

# 安装依赖（无锁文件）
RUN bun install

# 复制源代码
COPY . .

# 构建时需要的占位环境变量（实际运行时会被覆盖）
# 构建时使用 development 避免 REDIS 强制检查
ENV NODE_ENV=development
ENV ADMIN_PASSWORD=build_placeholder_12345678
ENV ADMIN_TOKEN_SECRET=build_placeholder_secret_20chars
ENV ADMIN_MAIL_USERNAME=build@example.com
ENV ADMIN_MAIL_PASSWORD=build_placeholder_12345678
ENV DEMO_PASSWORD=build_placeholder_12345678
ENV BETTER_AUTH_SECRET=build_placeholder_secret_20chars
ENV GITHUB_CLIENT_ID=build_placeholder
ENV GITHUB_CLIENT_SECRET=build_placeholder
ENV GOOGLE_CLIENT_ID=build_placeholder
ENV GOOGLE_CLIENT_SECRET=build_placeholder
ENV THEMOVIEDB_API_KEY=build_placeholder
ENV GOOGLE_BOOKS_API_KEY=build_placeholder
ENV IGDB_CLIENT_ID=build_placeholder
ENV IGDB_CLIENT_SECRET=build_placeholder
ENV LLM_API_KEY=build_placeholder
ENV LLM_MODEL_ID=build_placeholder
ENV LLM_BASE_URL=https://example.com
ENV REDIS_ENABLED=false
ENV VITE_BASE_URL=http://localhost:3000
ENV VITE_PUBLIC_POSTHOG_KEY=build_placeholder
ENV VITE_PUBLIC_POSTHOG_HOST=build_placeholder
ENV VITE_PUBLIC_POSTHOG_UI_HOST=build_placeholder

# 构建应用
RUN bun run build

# 生产阶段
FROM oven/bun:1-alpine AS runner

WORKDIR /app

# 设置环境变量
ENV NODE_ENV=production
ENV PORT=3000

# 复制构建产物和必要文件
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD bun --eval "fetch('http://localhost:3000/api/health').then(r => r.ok ? process.exit(0) : process.exit(1))" || exit 1

# 启动应用
CMD ["bun", "dist/server.js"]

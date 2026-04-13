# 使用官方 Bun 镜像作为构建阶段
FROM oven/bun:1 AS builder

WORKDIR /app

# 复制依赖文件
COPY package.json bun.lockb* ./

# 安装依赖
RUN bun install --frozen-lockfile

# 复制源代码
COPY . .

# 构建应用
RUN bun run build

# 生产阶段 - 使用更小的基础镜像
FROM oven/bun:1-slim AS runner

WORKDIR /app

# 安装必要的运行时依赖（用于 SQLite 和 sharp 等原生模块）
RUN apt-get update && apt-get install -y \
    libsqlite3-0 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 创建数据目录
RUN mkdir -p /app/instance /app/public/static

# 从构建阶段复制必要文件
COPY --from=builder /app/package.json ./
COPY --from=builder /app/bun.lockb* ./
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/drizzle ./drizzle
COPY --from=builder /app/public ./public

# 只安装生产依赖
RUN bun install --frozen-lockfile --production

# 设置环境变量
ENV NODE_ENV=production
ENV DATABASE_URL=file:./instance/site.db
ENV UPLOADS_DIR_NAME=static
ENV BASE_UPLOADS_LOCATION=./public/static/
ENV REDIS_ENABLED=false
ENV VITE_BASE_URL=http://localhost:3000

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD bun -e "fetch('http://localhost:3000/api/health').then(r => r.ok ? process.exit(0) : process.exit(1))" || exit 1

# 启动命令
CMD ["sh", "-c", "mkdir -p instance && bun run drizzle-kit push --force && bun run seed:achievements && bun run dist/server.js"]

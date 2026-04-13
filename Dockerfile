# 使用官方 Bun 镜像
FROM oven/bun:1

WORKDIR /app

# 复制依赖文件
COPY package.json bun.lockb* ./

# 安装所有依赖
RUN bun install

# 复制源代码
COPY . .

# 使用 Docker 专用配置构建（禁用 SSR 预渲染）
RUN bun --bun vite build --config vite.docker.config.ts

# 创建数据目录
RUN mkdir -p /app/instance /app/public/static

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD bun -e "fetch('http://localhost:3000').then(r => r.status < 500 ? process.exit(0) : process.exit(1)).catch(() => process.exit(1))" || exit 1

# 启动命令
CMD ["sh", "-c", "mkdir -p instance && bun run drizzle-kit push --force && bun run seed:achievements && bun run server.ts"]

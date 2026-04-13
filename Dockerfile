# 使用官方 Bun 镜像
FROM oven/bun:1 as base
WORKDIR /usr/src/app

# 安装依赖
FROM base AS install
COPY package.json bun.lockb* ./
RUN bun install

# 构建应用
FROM base AS prerelease
COPY --from=install /usr/src/app/node_modules ./node_modules
COPY . .
# 如果项目需要构建步骤（例如编译前端）
RUN bun run build

# 运行镜像
FROM base AS release
COPY --from=install /usr/src/app/node_modules ./node_modules
COPY --from=prerelease /usr/src/app/ .

# 暴露端口（根据项目配置，通常是 3000）
EXPOSE 3000

# 启动命令：先初始化数据库，再启动应用
CMD ["sh", "-c", "bun run new:db && bun run start"]

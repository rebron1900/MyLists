# 使用官方 Bun 镜像
FROM oven/bun:1 AS BASE
WORKDIR /usr/src/app

# 安装依赖阶段
FROM BASE AS INSTALL
COPY package.json bun.lock* ./
RUN bun install

# 最终运行镜像
FROM BASE AS RELEASE
# 从安装阶段拷贝 node_modules
COPY --from=INSTALL /usr/src/app/node_modules ./node_modules
# 拷贝所有源代码
COPY . .

# 关键：设置生产环境变量
ENV NODE_ENV=production
# 暴露端口
EXPOSE 3000

# 启动命令修改：
# 1. 自动生成数据库目录
# 2. 现场执行 build (避开 Docker buildx 的网络限制)
# 3. 运行初始化脚本并启动
CMD ["sh", "-c", "mkdir -p instance && bun run build && bun run new:db && bun run start"]

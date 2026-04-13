FROM oven/bun:1

WORKDIR /app

COPY package.json bun.lockb* ./
RUN bun install

COPY . .

RUN bun run build

ENV NODE_ENV=production
ENV PORT=3000
ENV DATABASE_URL=file:./instance/site.db
ENV UPLOADS_DIR_NAME=static
ENV BASE_UPLOADS_LOCATION=./public/static/
ENV REDIS_ENABLED=false

EXPOSE 3000

CMD ["sh", "-c", "mkdir -p instance && bun run drizzle-kit push --force && bun run seed:achievements && bun run server.ts"]

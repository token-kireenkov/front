
FROM node:20-alpine AS base

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

FROM node:20-alpine AS production

WORKDIR /app

COPY --from=base /app/.output /app/.output
COPY --from=base /app/node_modules /app/node_modules

ENV PORT=3001
EXPOSE 3001

CMD ["node", "/app/.output/server/index.mjs"]
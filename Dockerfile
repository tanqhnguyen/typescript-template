FROM node:14-alpine3.12 AS base

RUN mkdir /app
WORKDIR /app

COPY package.json /app/package.json
COPY package-lock.json /app/package-lock.json

RUN npm ci --only=production

FROM base AS development
RUN npm install --only=development

ENTRYPOINT [ "/app/scripts/entrypoint.sh" ]

# The production build
FROM base AS production

RUN npm install forever -g
ENV NODE_ENV=production

COPY . /app/

HEALTHCHECK --interval=5s --timeout=5s --retries=10 \
    CMD wget --quiet --tries=1 --spider http://localhost:5000/status || exit 1

RUN npm run build

EXPOSE 5000

CMD npm start

ENTRYPOINT [ "/app/scripts/entrypoint.sh" ]

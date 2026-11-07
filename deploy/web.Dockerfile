# Web image used by .github/workflows/docker-images.yml.
# Mirrors upstream CI (web.yml): Node 24, pnpm 11.11.0, `pnpm install --trust-lockfile`.
# The upstream web/Dockerfile installs the newest pnpm (now a major ahead of the lockfile)
# and runs `pnpm install` before the source is present, so the `nuxt prepare` postinstall
# has no nuxt.config to load. Kept under deploy/ so "Sync fork" never conflicts.

# build stage
FROM node:24-alpine AS build

WORKDIR /app

# No .git inside the image; skip the husky "prepare" hook instead of letting it complain.
ENV HUSKY=0
ENV CI=true

RUN npm install -g pnpm@11.11.0

# Source first so the postinstall (nuxt prepare) and generate see nuxt.config and .env
COPY . .

RUN pnpm install --trust-lockfile --frozen-lockfile

RUN pnpm run generate

# production stage
FROM nginx:stable-alpine AS production
COPY --from=build /app/.output/public /usr/share/nginx/html

COPY ./nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 3000
CMD ["nginx", "-g", "daemon off;"]

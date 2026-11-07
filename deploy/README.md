# Self-host on Unraid with prebuilt images

This fork adds a GitHub Actions workflow (`.github/workflows/docker-images.yml`) that builds the
API and web images and pushes them to GitHub Container Registry on every push to `main`:

```
ghcr.io/harikiran-lab/httpsms-api:latest
ghcr.io/harikiran-lab/httpsms-web:latest
```

Extra tags per build: short commit (`f352d81`) and date (`20261107`).

## One-time setup

1. **Enable Actions on the fork.** GitHub disables workflows on forks until you open the
   *Actions* tab and click *I understand my workflows, go ahead and enable them*.
2. **Fill in `deploy/web.env`** with your Unraid IP and your Firebase web-app config, then push.
   The web UI is a static Nuxt build, so these values are baked in at build time.
3. **Run the workflow** (Actions -> docker-images -> Run workflow) or just push a change.
4. **Make both packages public** so Unraid can pull anonymously:
   GitHub profile -> Packages -> `httpsms-api` -> Package settings -> Change visibility -> Public.
   Repeat for `httpsms-web`. Alternatively keep them private and run `docker login ghcr.io` on Unraid.
5. **Install the Unraid templates.** Copy `deploy/unraid/*.xml` to
   `/boot/config/plugins/dockerMan/templates-user/` on the Unraid box. They then show up under
   Docker -> Add Container -> Template -> User templates.
6. Add `httpsms-api` first. Required fields:
   - `DATABASE_URL` / `DATABASE_URL_DEDICATED` (same value is fine) pointing at your Postgres
   - `REDIS_URL`
   - `GCP_PROJECT_ID` and `FIREBASE_CREDENTIALS` (service-account JSON as one line)
   - `APP_URL` with your Unraid IP
7. Create the events-queue system user in the `users` table (see the upstream README,
   "Self Host Setup"), put its ID and API key in `EVENTS_QUEUE_USER_ID` / `EVENTS_QUEUE_USER_API_KEY`,
   restart the API.
8. Add `httpsms-web`. It only needs the port mapping.

## Updating

- **Upstream changes:** use GitHub's *Sync fork* button on the repo page, which pushes to `main`
  and triggers a rebuild. Then *Force update* the containers on Unraid.
- **Web UI config:** edit `deploy/web.env`, commit, push.
- **Pin a version:** set the Unraid Repository field to a commit or date tag instead of `latest`.

## Notes

- The web image is built from `deploy/web.Dockerfile`, not `web/Dockerfile`. It is the same file
  with Node and pnpm pinned to what upstream CI uses (Node 24, pnpm 11.11.0); the upstream
  Dockerfile pulls the newest pnpm, which has moved a major ahead of the lockfile and fails.

- The upstream `web.yml` and `api.yml` workflows also run on this fork. The `web.yml` deploy job
  will fail because it needs Cloudflare/Firebase secrets you don't have; that is harmless. Disable
  it under Actions if the red X bothers you.
- Scheduled workflows are off on forks, so there is no automatic weekly rebuild; sync and push instead.

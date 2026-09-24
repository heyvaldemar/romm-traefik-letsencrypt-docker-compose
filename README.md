# RomM + Traefik + Let's Encrypt on Docker Compose

[![Deployment Verification](https://github.com/heyvaldemar/romm-traefik-letsencrypt-docker-compose/actions/workflows/deployment-verification.yml/badge.svg?branch=main)](https://github.com/heyvaldemar/romm-traefik-letsencrypt-docker-compose/actions/workflows/deployment-verification.yml)

This repository deploys [RomM](https://github.com/rommapp/romm) 5, a self-hosted manager for your game library with in-browser play, behind Traefik with automatic Let's Encrypt TLS, a MariaDB database, and a backups service whose restore scripts CI runs on every push.

## Getting started

```bash
# 1. Clone
git clone https://github.com/heyvaldemar/romm-traefik-letsencrypt-docker-compose
cd romm-traefik-letsencrypt-docker-compose

# 2. Create the two Docker networks the stack expects
docker network create traefik-network
docker network create romm-network

# 3. Copy the environment template and fill in required values
cp .env.example .env
$EDITOR .env
# ^ Required: TRAEFIK_ACME_EMAIL, TRAEFIK_HOSTNAME, TRAEFIK_BASIC_AUTH,
#   ROMM_HOSTNAME, ROMM_DB_PASSWORD, ROMM_DB_ADMIN_PASSWORD,
#   ROMM_AUTH_SECRET_KEY. See .env.example for generation commands.

# 4. Deploy
docker compose -f romm-traefik-letsencrypt-docker-compose.yml -p romm up -d
```

Within a few minutes, `https://${ROMM_HOSTNAME}` opens RomM's setup wizard and `https://${TRAEFIK_HOSTNAME}` serves the basic-auth protected Traefik dashboard, both with fresh Let's Encrypt certificates.

### What success looks like

```bash
docker compose -f romm-traefik-letsencrypt-docker-compose.yml -p romm ps
# Expected: mariadb, romm and traefik "(healthy)", backups running

curl -fsS "https://${ROMM_HOSTNAME}/api/heartbeat" | jq -r .SYSTEM.VERSION
# Expected: the version the compose file pins
```

### Common first-deploy issues

- **Cert issuance fails.** DNS hasn't propagated to your server's IP yet, or port 80/443 isn't reachable from the internet. Confirm with `dig +short ${ROMM_HOSTNAME}`.
- **`docker compose up` fails with `set in .env`.** A required variable is empty in `.env`; the error names it.
- **Network not found.** Step 2 (the `docker network create` commands) was skipped.
- **The library is empty after a scan.** RomM expects one folder per platform; see the [folder structure](https://docs.romm.app) it reads.

## Your library

The compose file mounts `./library` next to it as the library by default, and `.gitignore` keeps everything in that directory out of git, so a `git add -A` can never commit your game files. To use a collection that lives elsewhere, set `ROMM_LIBRARY_PATH` in `.env`.

An optional `config.yml` (start from `config/config.example.yml`) goes in `config/`; it is gitignored too, so editing it never blocks `update.sh`.

### Metadata providers

Every provider is optional: RomM starts and scans without any, and gets better with each one configured. ScreenScraper, RetroAchievements, SteamGridDB, IGDB and MobyGames each need an account or key from that service, and Hasheous is on by default. Where to get each: [RomM's metadata provider guide](https://docs.romm.app/latest/Getting-Started/Metadata-Providers/). They are third-party services with their own terms.

## What this repository does not contain

No ROM, BIOS, firmware or other copyrighted game file is included, linked to, or described how to obtain. RomM manages and plays a library you already own: use dumps of cartridges and discs you have, and check that doing so is lawful where you live. This repository deploys the upstream [rommapp/romm](https://github.com/rommapp/romm) image (AGPL-3.0) unmodified.

## Supply chain trust

This repository is a deployment template, not a custom image. It orchestrates three upstream images:

- [`rommapp/romm`](https://hub.docker.com/r/rommapp/romm): RomM upstream
- [`mariadb`](https://hub.docker.com/_/mariadb): database, Docker Hub official image
- [`traefik`](https://hub.docker.com/_/traefik): reverse proxy, Docker Hub official image

Each is pinned to `tag@sha256:<digest>` as an interpolation default in the compose file's `x-images` block. Compose pulls by digest, so two users deploying on different days get byte-identical image manifests, and `git pull` alone delivers the combination this repository has tested. Setting `ROMM_IMAGE_TAG`, `ROMM_MARIADB_IMAGE_TAG` or `TRAEFIK_IMAGE_TAG` in `.env` overrides a default when you deliberately want a different version.

The daily Pin Freshness workflow re-resolves each pinned tag against its registry and compares the pinned RomM version with the latest upstream release. Any drift fails that run and notifies the maintainer. GitHub Actions are pinned by commit SHA with version comments; Dependabot keeps those fresh.

### Verify what you deploy

Every release from v1.0.0 on carries three files made on GitHub's runner with a short-lived identity and no stored key: `romm-traefik-letsencrypt-docker-compose-<tag>.tar.gz`, a `git archive` of exactly the tree the tag points at; `romm-traefik-letsencrypt-docker-compose-<tag>.tar.gz.sigstore.json`, a keyless [Sigstore](https://www.sigstore.dev/) signature over it; and `romm-traefik-letsencrypt-docker-compose-<tag>.intoto.jsonl`, [SLSA](https://slsa.dev/) build provenance from the SLSA generator. To check them with nothing from this repository trusted:

```bash
cosign verify-blob romm-traefik-letsencrypt-docker-compose-<tag>.tar.gz \
  --bundle romm-traefik-letsencrypt-docker-compose-<tag>.tar.gz.sigstore.json \
  --certificate-identity-regexp '^https://github.com/heyvaldemar/romm-traefik-letsencrypt-docker-compose/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com

slsa-verifier verify-artifact romm-traefik-letsencrypt-docker-compose-<tag>.tar.gz \
  --provenance-path romm-traefik-letsencrypt-docker-compose-<tag>.intoto.jsonl \
  --source-uri github.com/heyvaldemar/romm-traefik-letsencrypt-docker-compose
```

Add `--source-tag <tag>` for a release published after 24 September 2026, which is signed by the run that published it. The five releases before that date were signed by a run started by hand on `main`, so their provenance names the branch, not the tag; the archive is still the tag's tree, and the signature still belongs to this repository's workflow. The workflow that makes them is [`release-assets.yml`](.github/workflows/release-assets.yml).

## Production checklist

- [ ] **Generate every secret yourself**: the database passwords, `ROMM_AUTH_SECRET_KEY`, and the `TRAEFIK_BASIC_AUTH` hash.
- [ ] **Finish the setup wizard straight away.** Until the first account exists, whoever opens the hostname first creates it.
- [ ] **Verify Let's Encrypt cert issuance.** Watch `docker compose -p romm logs traefik -f` on first start for `Adding certificate for domain(s)`.
- [ ] **Lock down the Traefik dashboard.** Basic auth is basic. Consider Traefik's `IPAllowList` middleware or not exposing the dashboard publicly at all.
- [ ] **Back up the library yourself.** The backups service archives RomM's database and your saves and states, not the game files, which are yours and usually far larger.

## Unattended updates

Releases are the update channel: a tag is cut only after CI has booted the pinned images, upgraded from the previous release on the same volumes, and passed the smoke and restore tests. `update.sh` moves a deployment to the newest tag and nothing else:

```bash
./update.sh --dry-run   # show what would be applied
./update.sh             # update within the current major and redeploy
```

The script refuses to cross a MAJOR template version on its own, refuses to touch a checkout with local modifications, and names any variable that became required since your version before anything moves.

## Resource limits

Every service carries memory and CPU limits plus reservations as compose-level defaults: the same values CI boots the stack under. Override any of them in `.env` (the knobs are listed in `.env.example`) and the override survives every `git pull`. A library scan is the heaviest thing RomM does; if it is OOM-killed on a large collection, raise `ROMM_MEMORY_LIMIT`.

## Backups and restore

The `backups` service dumps the database and archives RomM's saves, states and uploads (`/romm/assets`) on its interval (`BACKUP_INTERVAL`, default 24h), reads each file back before naming it a backup, and prunes by age. Restore with the two scripts next to the compose file:

```bash
./romm-restore-database.sh            # list the database dumps and ask which
./romm-restore-database.sh <file>     # restore that dump
./romm-restore-application-data.sh    # the same for saves, states and uploads
```

Both stop RomM while they work and start it again afterwards, and both take every path and file name from the running backups container, so they cannot disagree with where the stack writes. Set `COMPOSE_PROJECT_NAME` if you started the stack with a `-p` other than `romm`.

## Container hardening

Every service runs with `security_opt: no-new-privileges:true`. Infrastructure containers (the reverse proxy, the database, the backups service) run with `cap_drop: [ALL]` and add back only what their entrypoints need. The application container keeps the default capability set on purpose: upstream images assume it, and a wrong guess there is a boot loop in production rather than a hardening win. CI boots the stack under exactly these settings on every push.

## Testing

The [Deployment Verification](https://github.com/heyvaldemar/romm-traefik-letsencrypt-docker-compose/actions/workflows/deployment-verification.yml?query=branch%3Amain) workflow runs on every push, pull request, and every day at 06:00 UTC: shellcheck and actionlint, a Trivy scan of each pinned image, and a deploy that first starts the previous release on the same volumes, upgrades it, and requires RomM's heartbeat through Traefik to report the version the compose file pins. It then runs the shipped restore scripts themselves: a marker written after a backup must be gone once that backup is restored, for the database and for the saves and states. Pin freshness is its own daily workflow, so this badge says whether the stack works, not whether a pin is one version behind.

---

## About the maintainer

<div align="center">

**Maintained by [Vladimir Mikhalev](https://github.com/heyvaldemar)** · Docker Captain · IBM Champion · AWS Community Builder

[YouTube](https://www.youtube.com/channel/UCf85kQ0u1sYTTTyKVpxrlyQ?sub_confirmation=1) · [Blog](https://heyvaldemar.com) · [LinkedIn](https://www.linkedin.com/in/heyvaldemar/)

</div>

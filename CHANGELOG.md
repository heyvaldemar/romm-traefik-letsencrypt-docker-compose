# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Security

- **`traefik:3.7` was rebuilt upstream**; the pin moved from `sha256:1336e85aaed2…` to `sha256:e9338a01a433…`. Same version, same tag, a rebuilt base image — the usual shape of a security fix in a base layer.

## [1.1.11] - 2026-10-27

### Security

- **`traefik:3.7` was rebuilt upstream**; the pin moved from `sha256:c8a121e4bb13…` to `sha256:1336e85aaed2…`. Same version, same tag, a rebuilt base image — the usual shape of a security fix in a base layer.
- **`mariadb:11.4` was rebuilt upstream**; the pin moved from `sha256:250e1609e93c…` to `sha256:d1891ede5a55…`. Same version, same tag, a rebuilt base image — the usual shape of a security fix in a base layer.

## [1.1.10] - 2026-10-23

### Changed

- **`rommapp/romm:5.4.0` moved to `rommapp/romm:5.4.1`.** The freshness check reported the lag; the deploy job booted the stack on the new image before this landed.

## [1.1.9] - 2026-10-23

### Security

- **`traefik:3.7` was rebuilt upstream**; the pin moved from `sha256:22a759fb803a…` to `sha256:c8a121e4bb13…`. Same version, same tag, a rebuilt base image — the usual shape of a security fix in a base layer.

## [1.1.8] - 2026-10-22

### Security

- **`traefik:3.7` was rebuilt upstream**; the pin moved from `sha256:6d3e069ee484…` to `sha256:22a759fb803a…`. Same version, same tag, a rebuilt base image — the usual shape of a security fix in a base layer.

## [1.1.7] - 2026-10-21

### Security

- **`traefik:3.7` was rebuilt upstream**; the pin moved from `sha256:0f6150202bc1…` to `sha256:6d3e069ee484…`. Same version, same tag, a rebuilt base image — the usual shape of a security fix in a base layer.

## [1.1.6] - 2026-10-17

### Security

- **`mariadb:11.4` was rebuilt upstream**; the pin moved from `sha256:1292844148b3…` to `sha256:250e1609e93c…`. Same version, same tag, a rebuilt base image — the usual shape of a security fix in a base layer.

## [1.1.5] - 2026-10-16

### Security

- **`traefik:3.7` was rebuilt upstream**; the pin moved from `sha256:575fa15b1350…` to `sha256:0f6150202bc1…`. Same version, same tag, a rebuilt base image — the usual shape of a security fix in a base layer.

## [1.1.4] - 2026-10-11

### Added

- **CI fails on an anonymous volume.** A `VOLUME` an image declares and no mount covers becomes an anonymous volume: never backed up, and replaced by an empty one on `down`/`up`. The deployment verification now inspects every container it starts and fails on one, unless `.github/anonymous-volumes` lists it with the reason. GLPI's data lived in exactly such a volume from 2026-08-31 to 2026-10-11.

### Changed

- **`rommapp/romm:5.3.1` moved to `rommapp/romm:5.4.0`.** The freshness check reported the lag; the deploy job booted the stack on the new image before this landed.

## [1.1.3] - 2026-10-09

### Security

- **`traefik:3.7` was rebuilt upstream**; the pin moved from `sha256:b588cb566045…` to `sha256:575fa15b1350…`. Same version, same tag, a rebuilt base image — the usual shape of a security fix in a base layer.

## [1.1.2] - 2026-10-07

### Security

- **`traefik:3.7` was rebuilt upstream**; the pin moved from `sha256:24841fe2de73…` to `sha256:b588cb566045…`. Same version, same tag, a rebuilt base image — the usual shape of a security fix in a base layer.

### Fixed

- **`update.sh` no longer stops without a word when a release adds a variable and no compose file requires one.** The search for `${VAR:?}` came back empty, and under `pipefail` that empty result ended the script with status 1 right after it listed the new variables.
- **`update.sh` stops on a `.env` it cannot read, before the checkout.** It used to fall through: every new required variable read as "not set", or, with none, the tree moved to the new tag and `docker compose up` failed on the permission. Now it names the file, its owner and mode, and changes nothing.

## [1.1.1] - 2026-10-02

### Security

- **`mariadb:11.4` was rebuilt upstream**; the pin moved from `sha256:70cc072b29b4…` to `sha256:1292844148b3…`. Same version, same tag, a rebuilt base image — the usual shape of a security fix in a base layer.

## [1.1.0] - 2026-09-26

### Added

- **Traefik's timeouts on the HTTPS entry point can be set from `.env`.**
  `TRAEFIK_READ_TIMEOUT`, `TRAEFIK_WRITE_TIMEOUT` and `TRAEFIK_IDLE_TIMEOUT`
  default to Traefik's own values (60s, 0s, 180s), so nothing changes unless
  you set them. Traefik reads its static configuration from one source, here
  the command in the compose file, and an override file can only replace that
  command whole; a variable is the way to tune it and keep taking updates.
  The same change was asked for in the [Keycloak template](https://github.com/heyvaldemar/keycloak-traefik-letsencrypt-docker-compose), and every template in the fleet gets it at once.

## [1.0.0] - 2026-09-23

### Added

- **Published, on RomM 5 and at the fleet's standard.** This repository was
  private while a committed `.env` sat in it; that file has been removed from
  every commit before publication, and a full-history secret scan finds nothing.
- **RomM 5.3.1**, pinned by digest with MariaDB 11.4 and Traefik 3.7 in the
  compose file's `x-images` block. RomM 5 runs its own Redis, so the separate
  Redis service is gone; the metadata providers are the ones upstream now
  recommends, every one optional.
- **The library is `./library` by default and never committed.** The previous
  version mounted `/mnt/c/library`, a Windows path, and nothing kept a library
  out of git. `ROMM_LIBRARY_PATH` points it anywhere.
- **Backups whose restore CI proves.** The backups service dumps the database
  and archives saves and states, reading each file back before naming it a
  backup; the restore scripts take every path from the running backups
  container and accept the file name as an argument, and CI runs them: a marker
  written after a backup must be gone once that backup is restored.
- **Verification** on every push, pull request and every day: lint, a Trivy
  scan of each pinned image, an upgrade drill from the previous release, and a
  heartbeat through Traefik that must report the pinned version.
- **Pin Freshness**, its own daily workflow; **`./update.sh`**; resource limits,
  `no-new-privileges` and capability drops; OpenSSF Scorecard.
- **What the repository does not contain** is stated in the README: no ROM,
  BIOS or firmware, and no pointer to any.

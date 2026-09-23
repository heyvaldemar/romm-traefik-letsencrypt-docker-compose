# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

_(no unreleased changes yet)_

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

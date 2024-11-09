# RomM with Let's Encrypt Using Docker Compose

[![Deployment Verification](https://github.com/heyvaldemar/romm-traefik-letsencrypt-docker-compose/actions/workflows/00-deployment-verification.yml/badge.svg)](https://github.com/heyvaldemar/romm-traefik-letsencrypt-docker-compose/actions)

The badge displayed on my repository indicates the status of the deployment verification workflow as executed on the latest commit to the main branch.

**Passing**: This means the most recent commit has successfully passed all deployment checks, confirming that the Docker Compose setup functions correctly as designed.

📙 The complete installation guide is available on my [website](https://www.heyvaldemar.com/install-romm-using-docker-compose/).

❗ Change variables in the `.env` to meet your requirements.

❗ The values for `ROMM_AUTH_SECRET_KEY` can be generated using the command:

`openssl rand -hex 32`

❗ Generate an API key at [MobyGames](https://www.mobygames.com/info/api/) and assign it to `ROMM_MOBYGAMES_API_KEY`.

❗ Generate an API key at [SteamGridDB](https://www.steamgriddb.com/profile/preferences/api) and assign it to `ROMM_STEAMGRIDDB_API_KEY`.

❗ Edit the environment variables `ROMM_IGDB_CLIENT_ID` and `ROMM_IGDB_CLIENT_SECRET` to the values retrieved from your IGDB account:

1. Sign up for a free Twitch account.
2. Enable Two-Factor Authentication.
3. Register your application in the Twitch Developer Portal:
   - Name your application uniquely.
   - Add a URL (it doesn’t have to be valid, just unique).
   - Choose a category and set the Client Type to "Confidential."
4. Complete the Captcha and click "Create."
5. Click "Manage" next to your new app to view your client ID (similar to a username).
6. Click "New Secret" to generate a secret key (similar to a password). Note: This secret is shown only once; make sure to record it.

💡 Note that the `.env` file should be in the same directory as `romm-traefik-letsencrypt-docker-compose.yml`.

Create networks for your services before deploying the configuration using the commands:

`docker network create traefik-network`

`docker network create romm-network`

Deploy RomM using Docker Compose:

`docker compose -f romm-traefik-letsencrypt-docker-compose.yml -p romm up -d`

# Docker Volumes Configuration for RomM

This section details the Docker volume bindings used by RomM to manage and store various data components:

- `romm-data:/romm/resources`: This volume stores resources fetched from IGDB, such as game covers, screenshots, and other media, essential for enriching the game display and user experience.

- `redis-data:/redis-data`: Used for caching data essential for the performance of background tasks, improving the efficiency and responsiveness of the application.

- `./library:/romm/library`: Maps the local `library` directory to the container, serving as the primary storage for your game library where all game files are accessed and managed.

- `./assets:/romm/assets`: Local storage for uploaded game saves, states, and other related assets, ensuring they are persisted and readily accessible.

- `./config:/romm/config`: Contains the `config.yml` configuration file, centralizing the application's settings and configurations in a single, easily accessible location.

Each volume is mapped to a specific directory inside the container to ensure proper data management and isolation, aligning with RomM’s operational requirements and data handling strategies.

# Directory Structure

Referencing the installation guide, RomM necessitates a specific directory structure to function correctly. Below are the two endorsed directory configurations:

<table>
 <tr>
    <th><b>Preferred Structure A</b></th>
    <th><b>Alternative Structure B</b></th>
 </tr>
 <tr>
  <td>
    <code>library/roms/gbc/rom_1.gbc</code>
  </td>
  <td>
    <code>library/gbc/roms/rom_1.gbc</code>
  </td>
 </tr>
 <tr>
    <td>
      <pre>
        library/
        ├─ roms/
        │  ├─ gbc/
        │  │  ├─ rom_1.gbc
        │  │  ├─ rom_2.gbc
        │  ├─ gba/
        │  │  ├─ rom_1.gba
        │  │  ├─ rom_2.gba
        │  ├─ ps/
        │     ├─ my_multifile_game/
        │     │   ├─ my_game_cd1.iso
        │     │   ├─ my_game_cd2.iso
        │     ├─ rom_1.iso
        ├─ bios/
        │  ├─ gba/
        │  │  ├─ gba_bios.bin
        │  ├─ ps/
        │     ├─ scph1001.bin
        │     ├─ scph5501.bin
        │     ├─ scph5502.bin
      </pre>
    </td>
    <td>
      <pre>
        library/
        ├─ gbc/
        │  ├─ roms/
        │     ├─ rom_1.gbc
        │     ├─ rom_2.gbc
        ├─ gba/
        │  ├─ roms/
        │     ├─ rom_1.gba
        │     ├─ rom_2.gba
        │  ├─ bios/
        │     ├─ gba_bios.bin
        ├─ ps/
        │  ├─ roms/
        │     ├─ my_multifile_game/
        │     │  ├─ my_game_cd1.iso
        │     │  ├─ my_game_cd2.iso
        │     ├─ rom_1.iso
        │  ├─ bios/
        │     ├─ scph1001.bin
        │     ├─ scph5501.bin
        │     ├─ scph5502.bin
      </pre>
    </td>
 </tr>
</table>

# Supported Platforms

Adhering to the RomM directory structure ensures compatibility across all platforms listed on the [Supported Platforms](https://github.com/rommapp/romm/wiki/Supported-Platforms) page. **Directory names are case-sensitive and must match exactly with those listed.** RomM scans directories to determine the platform, fetching game data, metadata, and artwork accordingly.

# Backups

The `backups` container in the configuration is responsible for the following:

1. **Database Backup**: Creates compressed backups of the MariaDB database using pg_dump.
Customizable backup path, filename pattern, and schedule through variables like `MARIADB_BACKUPS_PATH`, `MARIADB_BACKUP_NAME`, and `BACKUP_INTERVAL`.

2. **Application Data Backup**: Compresses and stores backups of the application data on the same schedule. Controlled via variables such as `DATA_BACKUPS_PATH`, `DATA_BACKUP_NAME`, and `BACKUP_INTERVAL`.

3. **Backup Pruning**: Periodically removes backups exceeding a specified age to manage storage. Customizable pruning schedule and age threshold with `MARIADB_BACKUP_PRUNE_DAYS` and `DATA_BACKUP_PRUNE_DAYS`.

By utilizing this container, consistent and automated backups of the essential components of your instance are ensured. Moreover, efficient management of backup storage and tailored backup routines can be achieved through easy and flexible configuration using environment variables.

# romm-restore-database.sh Description

This script facilitates the restoration of a database backup:

1. **Identify Containers**: It first identifies the service and backups containers by name, finding the appropriate container IDs.

2. **List Backups**: Displays all available database backups located at the specified backup path.

3. **Select Backup**: Prompts the user to copy and paste the desired backup name from the list to restore the database.

4. **Stop Service**: Temporarily stops the service to ensure data consistency during restoration.

5. **Restore Database**: Executes a sequence of commands to drop the current database, create a new one, and restore it from the selected compressed backup file.

6. **Start Service**: Restarts the service after the restoration is completed.

To make the `romm-restore-database.shh` script executable, run the following command:

`chmod +x romm-restore-database.sh`

Usage of this script ensures a controlled and guided process to restore the database from an existing backup.

# romm-restore-application-data.sh Description

This script is designed to restore the application data:

1. **Identify Containers**: Similarly to the database restore script, it identifies the service and backups containers by name.

2. **List Application Data Backups**: Displays all available application data backups at the specified backup path.

3. **Select Backup**: Asks the user to copy and paste the desired backup name for application data restoration.

4. **Stop Service**: Stops the service to prevent any conflicts during the restore process.

5. **Restore Application Data**: Removes the current application data and then extracts the selected backup to the appropriate application data path.

6. **Start Service**: Restarts the service after the application data has been successfully restored.

To make the `romm-restore-application-data.sh` script executable, run the following command:

`chmod +x romm-restore-application-data.sh`

By utilizing this script, you can efficiently restore application data from an existing backup while ensuring proper coordination with the running service.

# Author

I’m Vladimir Mikhalev, the [Docker Captain](https://www.docker.com/captains/vladimir-mikhalev/), but my friends can call me Valdemar.

🌐 My [website](https://www.heyvaldemar.com/) with detailed IT guides\
🎬 Follow me on [YouTube](https://www.youtube.com/channel/UCf85kQ0u1sYTTTyKVpxrlyQ?sub_confirmation=1)\
🐦 Follow me on [Twitter](https://twitter.com/heyValdemar)\
🎨 Follow me on [Instagram](https://www.instagram.com/heyvaldemar/)\
🧵 Follow me on [Threads](https://www.threads.net/@heyvaldemar)\
🐘 Follow me on [Mastodon](https://mastodon.social/@heyvaldemar)\
🧊 Follow me on [Bluesky](https://bsky.app/profile/heyvaldemar.bsky.social)\
🎸 Follow me on [Facebook](https://www.facebook.com/heyValdemarFB/)\
🎥 Follow me on [TikTok](https://www.tiktok.com/@heyvaldemar)\
💻 Follow me on [LinkedIn](https://www.linkedin.com/in/heyvaldemar/)\
🐈 Follow me on [GitHub](https://github.com/heyvaldemar)

# Communication

👾 Chat with IT pros on [Discord](https://discord.gg/AJQGCCBcqf)\
📧 Reach me at ask@sre.gg

# Give Thanks

💎 Support on [GitHub](https://github.com/sponsors/heyValdemar)\
🏆 Support on [Patreon](https://www.patreon.com/heyValdemar)\
🥤 Support on [BuyMeaCoffee](https://www.buymeacoffee.com/heyValdemar)\
🍪 Support on [Ko-fi](https://ko-fi.com/heyValdemar)\
💖 Support on [PayPal](https://www.paypal.com/paypalme/heyValdemarCOM)

# Disclaimer

This repository contains a Docker Compose configuration that references third-party Docker images. **I am not the creator or maintainer of these images** and have no control over their content. By using this configuration, you acknowledge that:

1. **You are solely responsible** for verifying the contents, licensing, and legality of any third-party Docker images referenced in this repository.
2. This configuration does **not include any ROM, BIOS, or other copyrighted files**. You are responsible for ensuring that any files you use comply with applicable licensing and copyright laws.
3. **No liability** is assumed for any legal issues or damages that arise from the use or misuse of this configuration and the images it references.

Please review all relevant licensing terms and only proceed if you have the legal right to use all components.

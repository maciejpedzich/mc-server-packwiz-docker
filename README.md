# mc-server-packwiz-docker

If you like Docker and keeping all your Minecraft Java server mods in one place using [packwiz](https://packwiz.infra.link/), as well as keeping track of all changes with Git, then this template repository is for you!

It comes with:

- a sample packwiz modpack
- a lightweight HTTP server image based on [BusyBox](https://hub.docker.com/_/busybox) that's used with [`packwiz-installer`](https://packwiz.infra.link/tutorials/installing/packwiz-installer) by [Minecraft Server on Docker](https://docker-minecraft-server.readthedocs.io/en/latest)
- a setup script, which not only lets you reinitialise the modpack, but also generates a minimal `.env` file for the Minecraft Server along with Git hooks for automatically refreshing the modpack's index (while also preventing files in `.dockerignore` from getting listed)

## Initial setup

> [!WARNING]  
> Make sure to audit the contents of `setup.sh` before running it!
> If you've noticed potentially malicious code, notify me immediately [via email](mailto:contact@maciejpedzi.ch).

```sh
git clone https://github.com/maciejpedzich/mc-server-packwiz-docker
cd mc-server-packwiz-docker
sudo chmod +x setup.sh
./setup.sh
```

## Launching the Minecraft server

```sh
sudo docker compose build
sudo docker compose up -d
```

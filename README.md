# SimEnv Shareable Build Context

This directory contains a Linux-oriented build context for a shareable Docker image. The built image includes:

- Ubuntu 20.04
- ROS Noetic
- Gazebo Classic 11
- CUDA 11.8
- LibTorch 2.7.1 + cu118 at `/opt/libtorch`
- SimEnv source and compiled catkin workspace at `/ws/SimEnv`

This repository is not fully self-contained at Git level:

- `build-image.sh` downloads the LibTorch archive from the official PyTorch CDN
- the Docker build fetches Ubuntu and ROS packages from network repositories

Those network locations are configurable through `.env` build args if the receiver needs different mirrors. The ROS signing key is vendored in this repository so image builds do not depend on fetching `ros.asc` from GitHub.

## Build

If you need proxies or alternate mirrors, copy `.env.example` to `.env` and fill in the variables.

```bash
cd a1-noetic-cu118-share
./build-image.sh
```

`build-image.sh` downloads the required LibTorch archive to `vendor/` on the host first, then runs `docker compose build`.

## Run

The default compose file is headless and does not assume a local X11 desktop.

Headless CPU:

```bash
docker compose up -d
```

Headless GPU:

```bash
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

GUI on a Linux X11 desktop:

```bash
docker compose -f docker-compose.yml -f docker-compose.gui.yml up -d
```

GUI with GPU:

```bash
docker compose -f docker-compose.yml -f docker-compose.gui.yml -f docker-compose.gpu.yml up -d
```

## Enter

```bash
docker exec -it simenv-a1-share bash
```

The shell already sources ROS and the SimEnv workspace.

## Start Simulation

Inside the container, the default startup is headless:

```bash
cd /ws/SimEnv
GUI=false ./auto.sh
```

Or from the host:

```bash
docker exec simenv-a1-share bash -lc 'cd /ws/SimEnv && GUI=false ./auto.sh'
```

If you intentionally started the GUI compose override and want the Gazebo desktop window:

```bash
docker exec simenv-a1-share bash -lc 'cd /ws/SimEnv && GUI=true ./auto.sh'
```

## Output

Runtime output is persisted to:

- `./output/generated_building`
- `./output/logs`
- `./output/results`

## Share

For Git-based sharing, commit and push this directory without the large LibTorch zip:

```bash
cd a1-noetic-cu118-share
git init
git add .
git commit -m "Add self-contained SimEnv Docker build context"
```

The `.gitignore` keeps `vendor/libtorch-cxx11-abi-shared-with-deps-2.7.1+cu118.zip` out of Git. After cloning, the receiver just runs:

```bash
git clone <your-repo>
cd a1-noetic-cu118-share
./build-image.sh
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

If you want to share a prebuilt image instead, build and export:

```bash
./build-image.sh
docker save -o simenv-a1-cu118-share.tar simenv-a1-cu118-share:latest
```

On another Linux host:

```bash
docker load -i simenv-a1-cu118-share.tar
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

## GPU Host Requirement

The host must have NVIDIA drivers and `nvidia-container-toolkit` configured. Use:

```bash
bash ./setup_nvidia_container_toolkit.sh
```

## Licensing Note

This build context does not relicense upstream SimEnv.

- the upstream source tree includes an AFL 3.0 license file in `SimEnv/LICENSE`
- the upstream SimEnv README also contains competition-specific wording about intended use

If you plan to redistribute this outside your own team or event context, review those upstream terms with the project owner before publishing.

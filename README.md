# SimEnv Shareable Container

This directory contains a self-contained build context for a Linux host. The image includes:

- Ubuntu 20.04
- ROS Noetic
- Gazebo Classic 11
- CUDA 11.8
- LibTorch 2.7.1 + cu118 at `/opt/libtorch`
- SimEnv source and compiled catkin workspace at `/ws/SimEnv`

## Build

If you need proxies, copy `.env.example` to `.env` and fill in the proxy variables.

```bash
cd /home/owlage/a1-noetic-cu118-share
./build-image.sh
```

`build-image.sh` downloads the required LibTorch archive to `vendor/` on the host first, then runs `docker compose build`.

## Run

CPU:

```bash
docker compose up -d
```

GPU:

```bash
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

## Enter

```bash
docker exec -it simenv-a1-share bash
```

The shell already sources ROS and the SimEnv workspace.

## Start Simulation

Inside the container:

```bash
cd /ws/SimEnv
./auto.sh
```

Or from the host:

```bash
docker exec simenv-a1-share bash -lc 'cd /ws/SimEnv && ./auto.sh'
```

## Output

Runtime output is persisted to:

- `./output/generated_building`
- `./output/logs`
- `./output/results`

## Share

For Git-based sharing, commit and push this directory without the large LibTorch zip:

```bash
cd /home/owlage/a1-noetic-cu118-share
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

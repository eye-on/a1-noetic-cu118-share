FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

SHELL ["/bin/bash", "-lc"]

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY
ARG http_proxy
ARG https_proxy
ARG no_proxy
ARG UBUNTU_MIRROR=http://archive.ubuntu.com/ubuntu
ARG UBUNTU_SECURITY_MIRROR=http://security.ubuntu.com/ubuntu
ARG ROS_MIRROR=http://packages.ros.org/ros/ubuntu

ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
ENV NO_PROXY=${NO_PROXY}
ENV http_proxy=${http_proxy}
ENV https_proxy=${https_proxy}
ENV no_proxy=${no_proxy}

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV ROS_DISTRO=noetic

RUN printf 'Acquire::Retries "5";\nAcquire::http::Timeout "30";\nAcquire::https::Timeout "30";\n' \
    > /etc/apt/apt.conf.d/80-retries

RUN retry_apt_install() { \
      local args=("$@"); \
      for attempt in 1 2 3; do \
        if apt-get update && apt-get install -y --no-install-recommends "${args[@]}"; then \
          return 0; \
        fi; \
        apt-get -f install -y || true; \
        dpkg --configure -a || true; \
        rm -rf /var/lib/apt/lists/*; \
        sleep 5; \
      done; \
      return 1; \
    }; \
    declare -f retry_apt_install > /usr/local/bin/retry_apt_install.sh

RUN sed -i \
    -e "s|http://archive.ubuntu.com/ubuntu|${UBUNTU_MIRROR}|g" \
    -e "s|http://security.ubuntu.com/ubuntu|${UBUNTU_SECURITY_MIRROR}|g" \
    /etc/apt/sources.list

RUN source /usr/local/bin/retry_apt_install.sh \
 && retry_apt_install \
    ca-certificates \
    curl \
    dirmngr \
    gpg \
    gnupg2 \
    lsb-release \
    mesa-utils \
    procps \
    python3 \
    python3-numpy \
    python3-pip \
    python3-scipy \
    python3-yaml \
    tzdata \
    unzip \
    wget \
    build-essential \
    cmake \
    git \
    libarmadillo-dev \
    liblcm-dev \
    pkg-config \
 && rm -rf /var/lib/apt/lists/*

COPY ros-archive-keyring.gpg /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] ${ROS_MIRROR} focal main" \
    > /etc/apt/sources.list.d/ros1.list

RUN source /usr/local/bin/retry_apt_install.sh \
 && retry_apt_install \
    gazebo11 \
    libgazebo11-dev \
    ros-noetic-desktop-full \
    ros-noetic-move-base-msgs \
 && rm -rf /var/lib/apt/lists/*

COPY vendor/libtorch-cxx11-abi-shared-with-deps-2.7.1+cu118.zip /opt/libtorch.zip
RUN cd /opt \
 && unzip -q libtorch.zip \
 && rm libtorch.zip

ENV LIBTORCH_HOME=/opt/libtorch
ENV CMAKE_PREFIX_PATH=/opt/libtorch:${CMAKE_PREFIX_PATH}
ENV LD_LIBRARY_PATH=/opt/libtorch/lib:/usr/local/cuda/lib64:${LD_LIBRARY_PATH}
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

COPY SimEnv /ws/SimEnv
RUN mkdir -p /ws/SimEnv/generated_building /ws/SimEnv/logs /ws/SimEnv/results

RUN cd /ws/SimEnv \
 && source /opt/ros/noetic/setup.bash \
 && catkin_make -j2

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
 && echo "source /opt/ros/noetic/setup.bash" >> /root/.bashrc \
 && echo "source /ws/SimEnv/devel/setup.bash" >> /root/.bashrc \
 && echo "export LIBTORCH_HOME=/opt/libtorch" >> /root/.bashrc \
 && echo "export CMAKE_PREFIX_PATH=/opt/libtorch:\$CMAKE_PREFIX_PATH" >> /root/.bashrc \
 && echo "export LD_LIBRARY_PATH=/opt/libtorch/lib:/usr/local/cuda/lib64:\$LD_LIBRARY_PATH" >> /root/.bashrc

WORKDIR /ws/SimEnv
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash"]

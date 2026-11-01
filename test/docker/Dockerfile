# Test image for seamlessvim. Build with:
#   docker build --build-arg BASE_IMAGE=archlinux:base-devel -t seamlessvim-test:arch test/docker
ARG BASE_IMAGE=archlinux:base-devel
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN     if command -v pacman >/dev/null 2>&1; then \
      pacman -Syu --noconfirm --needed sudo git curl ca-certificates findutils gzip unzip; \
    else \
      apt-get update \
      && apt-get install -y --no-install-recommends sudo git curl ca-certificates findutils gzip unzip \
      && rm -rf /var/lib/apt/lists/*; \
    fi \
 && useradd -m -s /bin/bash dev \
 && echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev \
 && chmod 0440 /etc/sudoers.d/dev \
 && mkdir -p /home/dev/.local/bin /home/dev/.local/share/nvim /home/dev/.local/share/coursier /home/dev/.cache/nvim \
 && chown -R dev:dev /home/dev

USER dev
ENV HOME=/home/dev
WORKDIR /home/dev

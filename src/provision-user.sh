#!/bin/bash
set -e -u -o pipefail
IFS=$'\n\t'
set -x

#GROUP=docker
#if id -nG "$USER" | grep -qw "$GROUP"; then
#    echo $USER belongs to $GROUP
#else
#    echo $USER does not belong to $GROUP
#fi

getent group docker >/dev/null || groupadd docker
usermod -aG docker vagrant
newgrp docker

# ------------------------------------------------------------------------------
# Docker
# ------------------------------------------------------------------------------
# Prepare Docker config
#mkdir -p ~/.docker

# Setup BuildX
docker run hello-world
docker run --privileged --rm tonistiigi/binfmt --install all
docker buildx create --name builder-default2 --driver docker-container --bootstrap --use

# ------------------------------------------------------------------------------
# SSH
# ------------------------------------------------------------------------------
ssh-keyscan github.com >> ~/.ssh/known_hosts

# ------------------------------------------------------------------------------
# Prepare User
# ------------------------------------------------------------------------------
# Change to the project directory on login
#echo 'cd /vagrant' >> ~/.bashrc

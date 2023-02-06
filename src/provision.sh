#!/bin/bash
set -e -u -o pipefail
IFS=$'\n\t'
set -x

# ------------------------------------------------------------------------------
# Install Docker
# ------------------------------------------------------------------------------
apt-get update
apt-get install --no-install-recommends --no-install-suggests --yes \
    ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install --no-install-recommends --no-install-suggests --yes \
    docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add "docker" group if it doesn't exist
getent group docker >/dev/null || groupadd docker
usermod -aG docker vagrant
#newgrp docker

# Prepare Docker config
su - vagrant -c 'mkdir -p ~/.docker'

# Setup BuildX
docker run --privileged --rm tonistiigi/binfmt --install all
docker buildx create --name builder-default --driver docker-container --bootstrap --use

# ------------------------------------------------------------------------------
# Improve SSH connection
# ------------------------------------------------------------------------------
head -n -2 /etc/ssh/sshd_config > tmp.txt && mv tmp.txt /etc/ssh/sshd_config
sed -i -e '/UseDNS no/s/^#//' /etc/ssh/sshd_config
sed -i -e '/GSSAPIAuthentication no/s/^#//' /etc/ssh/sshd_config
service ssh restart

su - vagrant -c 'ssh-keyscan github.com >> ~/.ssh/known_hosts'

# ------------------------------------------------------------------------------
# Install Password Manager for easy Docker Login
# ------------------------------------------------------------------------------
#DOCKER_CREDENTIAL_PASS_VERSION=0.7.0

#apt-get install --no-install-recommends --no-install-suggests --yes \
#    pass
#curl -fsSL -o /usr/local/bin/docker-credential-pass "https://github.com/docker/docker-credential-helpers/releases/download/v$DOCKER_CREDENTIAL_PASS_VERSION/docker-credential-pass-v$DOCKER_CREDENTIAL_PASS_VERSION.linux-amd64"
#chmod +x /usr/local/bin/docker-credential-pass

# ------------------------------------------------------------------------------
# Prepare User
# ------------------------------------------------------------------------------
# Change to the project directory on login
su - vagrant -c 'echo '\''cd /vagrant'\'' >> ~/.bashrc'

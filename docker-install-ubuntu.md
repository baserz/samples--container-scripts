
# 1 - Install docker engine

Information from: https://docs.docker.com/engine/install/ubuntu/

## Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

## Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

## Update & install
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

### Test commands
sudo systemctl status docker
sudo docker run hello-world

# 2 - Post install setup steps

Information from https://docs.docker.com/engine/install/linux-postinstall/

## Setup start at boot

sudo systemctl enable docker.service
sudo systemctl enable containerd.service

## Rights for gpu access and so forth

sudo usermod -aG docker $USER
sudo usermod -aG video $USER
sudo usermod -aG render $USER

sudo reboot

## Install portainer UI (for graphical UI management)
Install through the portainer docker-compose file. (docker logs contain setup key)
Url: https://localhost:9443/

# OPT: Installera SBX (Docker sandboxes, KRÄVER DOCKER LOGIN! KÖRS I MOLNET!)

## Eftersom sbx använder hårdvaruisolering (KVM) istället för vanliga containrar, måste din användare tillhöra kvm-gruppen för att kunna starta dem.

sudo apt-get update
sudo apt-get install -y docker-sbx
sudo usermod -aG kvm $USER
newgrp kvm
sbx login

## When setup is finieshed:
sbx run opencode




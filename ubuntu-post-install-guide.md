# Ubuntu post install guide

## Install ufw

sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing

## Basic protection

sudo apt install fail2ban apparmor-utils

On as standard?

## Clean up

sudo apt autoremove -y
sudo apt autoclean

## Swappiness optimization (if a lot of ram is available)

echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf


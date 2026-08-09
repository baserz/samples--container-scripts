# Install Clam AV

## 1. Install daemon, UI and update database

sudo apt update && sudo apt install clamav clamav-daemon clamtk -y
sudo systemctl stop clamav-freshclam
sudo freshclam
sudo systemctl enable --now clamav-freshclam clamav-daemon

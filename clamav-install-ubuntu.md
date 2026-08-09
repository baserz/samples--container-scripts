# Install Clam AV

## 1. Install daemon, UI and update database

sudo apt update && sudo apt install clamav clamav-daemon clamtk -y
sudo systemctl stop clamav-freshclam
sudo freshclam
sudo systemctl enable --now clamav-freshclam clamav-daemon

## 2. (Optional) adds support for right click on file and 'scan with clamAV

### Nautilus -q restarts file manager afterwards

sudo apt install clamtk-gnome
nautilus -q

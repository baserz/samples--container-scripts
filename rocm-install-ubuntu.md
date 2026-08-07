sudo apt update
sudo apt install -y rocm-cmake rocminfo rocm-smi radeontop
sudo usermod -a -G render,video $USER
sudo reboot



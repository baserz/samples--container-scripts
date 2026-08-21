# Install microsandbox

[https://github.com/superradcompany/microsandbox](https://github.com/superradcompany/microsandbox)

## Howto (Linux)

### KVM måste finnas

ls -l /dev/kvm
sudo usermod -aG kvm $USER   # logga ut/in efteråt

### Installera msb-CLI:t

curl -fsSL https://install.microsandbox.dev | sh
msb --version

### To inspect script

curl -fsSL https://install.microsandbox.dev -o install.sh
less install.sh
bash install.sh

### To test that it works

msb run debian

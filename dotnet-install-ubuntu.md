# Installera dotnet i Ubuntu

Dotnet finns som ubuntu snap men path strular till det..
Installera via apt istället..

## Installera dotnet SDK via apt

sudo apt update
sudo apt install --install-suggests dotnet-sdk-10.0

(--install-suggests ger dig även PDB-debug-symboler, vilket är bra att ha för just debugging i VS Code)

### Tips: Hur kontrollera var dotnet finns installerat

which dotnet
readlink -f $(which dotnet)
dirname $(readlink -f $(which dotnet))

### Sätt variabeln till dotnets install bibliotek som DOTNET_ROOT

export DOTNET_ROOT=/snap/bin/dotnet

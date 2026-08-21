# Setup of sandboxfile

## Prep

I sandboxfile måste man ändra <VÄRDENS-BRIDGE-IP> till värdens ip address (EJ localhost!). Så ip på datorn.

hostname -I

## Install

### 1. Skapa msb container

msb create --name opencode-agent --conf opencode-sandbox.yaml \
  -v /home/base/src:/workspace \
  -v /home/base/.config/opencode:/home/root/.config/opencode \
  -v /home/base/.local/share/opencode:/home/root/.local/share/opencode

### 2. Gör initiell setup (ḱör install scripts etc)

msb exec opencode-agent-- setup

### 3. Starta och använd

msb exec opencode-agent -w /workspace/Game1 -- opencode .

// msb exec opencode-agent -- setup
// msb exec opencode-agent -- bash

## Livscykel

msb stop opencode-agent
msb start opencode-agent
msb rm opencode-agent    # ta bort helt

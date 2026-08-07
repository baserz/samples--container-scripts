# syntax=docker/dockerfile:1
#
# Utvecklingsimage för OpenCode med stöd för .NET, Node.js/JS.
#
# ghcr.io/anomalyco/opencode:latest är den officiella OpenCode-imagen, men
# den är en minimal Alpine-image med bara opencode-binären + ripgrep - ingen
# git, inget .NET, ingen Node.js. Den fungerar bra om man bara vill köra
# opencode isolerat, men inte som en fullständig devcontainer.
#
# Den här imagen bygger istället ovanpå Microsofts officiella .NET SDK-image
# (Debian-baserad) och installerar Node.js samt OpenCode via OpenCodes eget
# officiella installationsskript (https://opencode.ai/install) - alltså
# samma binär som i ghcr.io/anomalyco/opencode, fast i en miljö som kan
# bygga .NET/JS/Node-projekt.

FROM mcr.microsoft.com/dotnet/sdk:10.0

ARG NODE_MAJOR=24
ARG USER_UID=1000
ARG USER_GID=1000

# --- Systemverktyg + Node.js (NodeSource) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl ca-certificates git unzip gnupg ripgrep build-essential sudo \
    && curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g npm@latest pnpm \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Icke-root-användare ---
# Matcha USER_UID/USER_GID mot din host-användare (se docker-compose.yml/.env)
# så att filer som skapas i den monterade källkodsmappen får rätt ägare.
RUN groupadd --gid ${USER_GID} opencode \
    && useradd --uid ${USER_UID} --gid ${USER_GID} --create-home --shell /bin/bash opencode \
    && echo "opencode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/opencode \
    && chmod 0440 /etc/sudoers.d/opencode

USER opencode
ENV HOME=/home/opencode
WORKDIR /workspace

# --- Installera OpenCode (officiellt installationsskript, alltid senaste release) ---
RUN curl -fsSL https://opencode.ai/install | bash
ENV PATH="${HOME}/.opencode/bin:${PATH}"

# git klagar annars på "dubious ownership" när /workspace ägs av en annan
# UID på hosten än i containern.
RUN git config --global --add safe.directory /workspace

ENTRYPOINT ["opencode"]
# Standardkommando: starta web-UI, lyssnandes på alla interfaces i containern.
CMD ["web", "--hostname", "0.0.0.0", "--port", "4096"]

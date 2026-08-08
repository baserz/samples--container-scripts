# Använd Microsofts officiella .NET SDK 10
FROM mcr.microsoft.com/dotnet/sdk:10.0-bookworm-slim

# Skapa en dedikerad användare utan root-rättigheter
RUN useradd --create-home --uid 1000 agentuser

WORKDIR /workspace

# Installera modern Node.js (t.ex. version 24.x) och nödvändiga verktyg
RUN apt-get update && apt-get install -y curl gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install -y nodejs git \
    && rm -rf /var/lib/apt/lists/*

# Se till att agentuser äger arbetsmappen
RUN chown -R agentuser:agentuser /workspace

# Byt till användaren utan root-rättigheter
USER agentuser

# Miljövariabler för att styra var .NET 10 och npm lägger sin cache
ENV DOTNET_CLI_HOME=/home/agentuser
ENV NPM_CONFIG_CACHE=/home/agentuser/.npm

ENTRYPOINT ["/bin/bash"]
# Utgå från den officiella .NET 10 SDK-avbildningen
FROM mcr.microsoft.com/dotnet/sdk:10.0

# Uppdatera paket, installera verktyg och Node.js (LTS/v22)
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

# Installera OpenCode globalt via dess korrekta npm-paketnamn
RUN npm install -g opencode-ai

# Sätt arbetskatalogen
WORKDIR /workspace

# Håll containern vid liv
CMD ["/bin/bash"]
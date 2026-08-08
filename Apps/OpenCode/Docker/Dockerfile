# Utgå från den officiella .NET 10 SDK-avbildningen
FROM mcr.microsoft.com/dotnet/sdk:10.0

# Environment variables to control .NET and npm cache locations
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=true \
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    ASPNETCORE_ENVIRONMENT=Development

# 1. Ta emot ID:n under byggsteget (kan sättas via build args om man vill ändra från 1000)
ARG USER_ID=1000
ARG GROUP_ID=1000

# 2. Skapa .local-strukturen i förväg (så att Docker inte skapar den som root senare)
RUN mkdir -p /home/ubuntu/.local/share/opencode \
    && mkdir -p /home/ubuntu/.local/state \
    && mkdir -p /home/ubuntu/.config/opencode \
    && mkdir -p /workspace

# 3. Ändra ägare REKURSIVT på HELA hemkatalogen och workspace
RUN chown -R ${USER_ID}:${GROUP_ID} /home/ubuntu \
    && chown -R ${USER_ID}:${GROUP_ID} /workspace

# Update package lists and install necessary tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    jq \
    procps \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*
    
# Install .NET workloads and global tools
# RUN dotnet workload install wasm-tools
# RUN dotnet workload install aspire
# RUN dotnet tool install --global dotnet-ef \
#    && dotnet tool install --global dotnet-outdated-tool

# Install the OpenCode AI CLI globally using npm
RUN npm install -g opencode-ai

# Set the working directory
WORKDIR /workspace

# Switch to the non-root user
USER ${USER_ID}:${GROUP_ID}

# Keep the container running and provide an interactive shell
CMD ["/bin/bash"]
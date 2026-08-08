# Utgå från den officiella .NET 10 SDK-avbildningen
FROM mcr.microsoft.com/dotnet/sdk:10.0

# Environment variables to control .NET and npm cache locations
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=true \
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    ASPNETCORE_ENVIRONMENT=Development

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
RUN dotnet workload install wasm-tools
RUN dotnet workload install aspire
RUN dotnet tool install --global dotnet-ef \
    && dotnet tool install --global dotnet-outdated-tool

# Install the OpenCode AI CLI globally using npm
RUN npm install -g opencode-ai

# Set the working directory
WORKDIR /workspace

# Keep the container running and provide an interactive shell
CMD ["/bin/bash"]
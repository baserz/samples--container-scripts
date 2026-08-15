# Kör opencode i microsandbox på Ubuntu

Den här guiden visar två vägar till samma mål. Välj den som passar dig:

- **Väg A — Docker 1:1**: Du behåller din befintliga `Dockerfile` och bygger imagen precis som idag. microsandbox körs bara *ovanpå* den färdiga imagen istället för `docker run`.
- **Väg B — msb-native**: Ingen Docker inblandad alls. Du utgår från en ren OCI-basimage (t.ex. `.NET SDK`-imagen från Microsoft) och låter msb installera Node.js och opencode direkt i sandboxen, med automatisk persistens mellan körningar.

| | Väg A (Docker 1:1) | Väg B (msb-native) |
|---|---|---|
| Kräver Docker/Podman installerat | Ja | Nej |
| Bygghastighet vid ändringar | Docker-cache (snabb ombyggnad) | Ingen lagerbyggcache — installationen körs en gång och persisteras sedan i sandboxens tillstånd |
| Reproducerbarhet mellan maskiner | Hög (samma image överallt) | Medel (samma Sandboxfile, men installationen sker vid första körning per maskin) |
| Passar bäst för | Team som redan har CI/CD runt Dockerfilen | Du som vill slippa en extra Docker-daemon och köra allt via `msb` |

---

## Förutsättningar (gäller båda vägarna)

```bash
# KVM måste finnas
ls -l /dev/kvm
sudo usermod -aG kvm $USER   # logga ut/in efteråt

# Installera msb-CLI:t
curl -fsSL https://install.microsandbox.dev | sh
msb --version
```

---

## Rekommenderade domäner för agentisk .NET-utveckling

Det här är de domäner som typiskt behöver ligga i `network.allow` för att en .NET/opencode-agent ska kunna installera paket, hämta verktyg och prata med modell-API:er. Lägg bara till det du faktiskt använder — en snävare lista är säkrare.

| Kategori | Domän | Varför |
|---|---|---|
| NuGet-paket | `api.nuget.org` | `dotnet restore` / `dotnet add package`, t.ex. Semantic Kernel, Microsoft.Extensions.AI, MCP-paket för .NET |
| .NET-installationsskript | `dotnetcli.azureedge.net`, `builds.dotnet.microsoft.com` | `dotnet-install.sh` och SDK/runtime-nedladdningar om du installerar fler .NET-versioner i sandboxen |
| Container-/basimages | `mcr.microsoft.com` | Om sandboxen själv drar fler Microsoft-images (t.ex. `msb pull`) |
| Node/npm | `registry.npmjs.org` | `npm install -g opencode-ai` och eventuella npm-baserade MCP-servrar |
| Node-installation | `deb.nodesource.com` | NodeSource-scriptet som installerar Node.js i Väg B |
| Källkod/paket från GitHub | `github.com`, `raw.githubusercontent.com`, `api.github.com`, `codeload.github.com`, `objects.githubusercontent.com` | Klona repon, hämta release-assets, `npx`-paket som pekar mot GitHub |
| Anthropic API | `api.anthropic.com` | Om opencode/agenten pratar med Claude-modeller |
| OpenAI API | `api.openai.com` | Om agenten pratar med OpenAI-modeller |
| Azure OpenAI | `<ditt-resursnamn>.openai.azure.com` | Byt ut mot din faktiska Azure OpenAI-endpoint, wildcards stöds inte |
| Lokal modellserver (Lemonade SDK m.fl.) | din värddators LAN-/bridge-IP | Se avsnittet om host-lokal nätverksåtkomst i tidigare del av konversationen — `localhost` inuti sandboxen pekar inte på värden |

**Domäner att medvetet *inte* lägga till** (håll dem borta om du inte aktivt behöver dem):
- `dc.services.visualstudio.com` och andra .NET-telemetriendpoints — redan avstängt via `DOTNET_CLI_TELEMETRY_OPTOUT=1`, men blockera dem ändå på nätverksnivå som extra skydd.
- Generella `*.microsoft.com`/`*.azure.com`-wildcards — för brett, öka istället listan med exakta subdomäner allt eftersom du stöter på anslutningsfel.

Verifiera alltid vad din specifika agent/opencode-konfiguration faktiskt kontaktar (t.ex. med `msb exec opencode -- curl -v https://...` eller genom att läsa nätverksloggen) innan du permanent låser en lista — annars är trial-and-error mot `network.allow` snabbast.

---

## Väg A — Docker 1:1

Använd det här om du redan har en fungerande `Dockerfile` (som `.NET 10 SDK + Node 22 + opencode-ai`) och bara vill byta ut `docker run` mot `msb run`.

### A1. Bygg imagen som vanligt

```bash
docker build \
  --build-arg USER_ID=$(id -u) \
  --build-arg GROUP_ID=$(id -g) \
  -t opencode-dotnet:local .
```

Ingenting i Dockerfilen behöver ändras — `USER ${USER_ID}:${GROUP_ID}` följer med i imagens OCI-metadata, som microsandbox respekterar precis som Docker gör.

### A2. Skapa ett msb-projekt som pekar på imagen

```bash
mkdir opencode-sandbox && cd opencode-sandbox
msb init
```

Redigera `Sandboxfile`:

```yaml
name: opencode-sandbox
sandboxes:
  opencode:
    image: opencode-dotnet:local
    workdir: /workspace
    volumes:
      - ./workspace:/workspace
    network:
      allow:
        - registry.npmjs.org
        - api.nuget.org
        - github.com
        - raw.githubusercontent.com
        - api.anthropic.com
        - api.openai.com
    scripts:
      start: /bin/bash
```

### A3. Kör sandboxen

```bash
msb run --sandbox opencode      # interaktivt skal
msb exec opencode -- opencode   # kör opencode direkt
```

### A4. (Valfritt) Gör den till en global genväg

```bash
msb install --image opencode-dotnet:local \
  --volume ~/opencode-projekt:/workspace \
  --workdir /workspace \
  oc

oc   # kör från valfri katalog
```

Nätverksregler som `network.allow` läggs till i efterhand i `~/.microsandbox/installs/oc/.menv/Sandboxfile`.

---

## Väg B — msb-native (ingen Docker)

Använd det här om du vill slippa Docker-daemonen helt och låta msb sköta hela livscykeln. Vi utgår direkt från Microsofts `.NET SDK`-image (den ligger på Microsoft Container Registry, som är ett vanligt OCI-register — samma image som i din Dockerfile) och kör installationsstegen som ett msb-script istället för `RUN`-rader.

### B1. Skapa projektet

```bash
mkdir opencode-sandbox-native && cd opencode-sandbox-native
msb init
```

### B2. Definiera sandboxen i Sandboxfile

```yaml
name: opencode-sandbox-native
sandboxes:
  opencode:
    image: mcr.microsoft.com/dotnet/sdk:10.0
    memory: 4096
    cpus: 2
    workdir: /workspace
    volumes:
      - ./workspace:/workspace
    envs:
      - DOTNET_CLI_TELEMETRY_OPTOUT=1
      - DOTNET_NOLOGO=true
      - DOTNET_USE_POLLING_FILE_WATCHER=true
      - ASPNETCORE_ENVIRONMENT=Development
    network:
      allow:
        - deb.nodesource.com
        - registry.npmjs.org
        - api.nuget.org
        - dotnetcli.azureedge.net
        - github.com
        - raw.githubusercontent.com
        - api.github.com
        - codeload.github.com
        - api.anthropic.com
        - api.openai.com
    scripts:
      setup: |
        apt-get update && apt-get install -y --no-install-recommends \
          curl git jq procps \
        && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
        && apt-get install -y --no-install-recommends nodejs \
        && rm -rf /var/lib/apt/lists/* \
        && npm install -g opencode-ai
      start: /bin/bash
```

### B3. Kör installationssteget en gång

```bash
msb run --sandbox opencode --exec setup
```

Det här kör `apt-get`/`npm install`-blocket. Eftersom det här är ett **projektbaserat** sandbox (skapat med `msb init`/`msb add`, inte `msb exe`) persisteras alla filändringar och installationer automatiskt i den lokala `./menv`-katalogen mellan körningar — du behöver alltså bara köra `setup` en gång per maskin, inte varje gång du startar sandboxen.

### B4. Använd sandboxen därefter

```bash
msb run --sandbox opencode        # interaktivt skal, opencode redan installerat
msb exec opencode -- opencode     # kör opencode direkt
```

### B5. (Valfritt) Gör den till en global genväg

```bash
msb install --image mcr.microsoft.com/dotnet/sdk:10.0 \
  --volume ~/opencode-projekt:/workspace \
  --workdir /workspace \
  oc-native
```

Öppna sedan `~/.microsandbox/installs/oc-native/.menv/Sandboxfile` och lägg till samma `scripts.setup`-block som i B2, kör `oc-native` en gång för att trigga installationen (`msb exec oc-native -- <setup-kommandot>` eller lägg `setup` som `start` första gången), och därefter är `oc-native` ett färdigt kommando.

---

## Att tänka på oavsett väg

- **Multi-stage-byggen i Sandboxfile** (en Dockerfile-liknande `builds:`-sektion) finns antytt i microsandbox-projektets egen dokumentation men är markerat som kommande funktion i skrivande stund — därför bygger Väg B installationen som ett vanligt `scripts`-steg istället för ett separat byggsteg.
- **Nätverksregler gäller bara vid körning**, inte vid ett eventuellt Docker-bygge. Om `setup`-scriptet i Väg B failar med anslutningsfel, dubbelkolla att alla domäner (`deb.nodesource.com`, `registry.npmjs.org`, `api.nuget.org` osv.) finns med i `network.allow`.
- **microsandbox är beta-mjukvara.** Testa båda vägarna i en engångssandbox (`msb exe --image ...`) innan du investerar i en permanent installation, särskilt exakt syntax för `scripts`/`--exec`, som kan skilja sig mellan versioner — kör `msb run --help` och `msb add --help` för att verifiera mot din installerade version.
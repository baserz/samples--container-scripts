# Lemonade & LLM optimering

## 0. Kontrollera docker-compose mot:

docker run -d \
  --name lemonade-server \
  -p 13305:13305 \
  -v lemonade-cache:/opt/lemonade/.cache/huggingface \
  -v lemonade-llama:/opt/lemonade/llama \
  -v lemonade-recipe:/opt/lemonade/.cache/lemonade \
  --device=/dev/kfd \
  --device=/dev/dri \
  ghcr.io/lemonade-sdk/lemonade-server:latest

##1. Slå på nightly

lemonade config set rocm_channel=nightly // KRITISKT!?

Det finns en känd bugg i vissa Lemonade-versioner: stable/preview ROCm-kanalerna saknar HIP-stöd för gfx1201 och faller tyst tillbaka till CPU (ingen felkod, bara 5-10x lägre hastighet). Endast nightly-kanalen har arch-specifika gfx120x-builds som fungerar korrekt på RDNA4 just nu. Kör och verifiera i loggarna att du ser gfx1201 initieras i llama-server (inte bara CPU-info), plus håll koll med rocm-smi eller amd-smi att GPU-utnyttjandet faktiskt går upp under inferens. Annars sitter du och kör på CPU utan att märka det.

##2. Perf level på graqfikkortet

Om rocm-smi säger power save mode etc ->
Set performance mode: Force the card out of power-saving clocks by running rocm-smi --setperflevel high or auto.

## 2. Sätt ROCm som default-backend i config.json (i lemonade-recipe-volymen)

{ "llamacpp": { "backend": "rocm" } }

Notera: image kör som opriviligerad user lemonade (UID 10001) – kolla att dina volymer har rätt ägare om du migrerar från en äldre root-baserad container.

Prestandaavvägning värd att känna till: på gfx1201 vinner Vulkan generellt token-generation (tg), medan ROCm ofta vinner prompt-processing (pp). Om du kör mycket agentisk användning med stora promptar (RAG, kod-kontext) – vilket 16k/32k antyder – kan ROCm faktiskt vara rätt val trots att ren tg-hastighet kan vara något lägre.

## Övrigt att tänka på i containern:

Om du begränsat containern med --cpus, se till att den får minst 8 vCPU – annars blir CPU-offloaded MoE-beräkning (för Qwen-lagren som ligger på CPU) flaskhalsen.
--no-mmap kan vara värt att testa om du märker konstig swap-liknande beteende när expertvikter ligger delvis i RAM, men lämna det av som default först.
Mina --n-cpu-moe-siffror bygger på uppskattad genomsnittlig bitdensitet för UD-dynamisk kvantisering – exakt fördelning varierar per tensor, så betrakta dem som startpunkter och justera ±2-4 baserat på om laddningen OOM:ar eller om rocm-smi visar ledig VRAM kvar.

--------------------------------------------------------------------

GENERALLT: SIKTA MOT 85% VRAM usage i rocm-smi.

--------------------------------------------------------------------

## ------------- GEMMA4 --------------

### gemma-4-26B-A4B-it-GGUF-UD-Q4_K_M   [REKOMMENDERAS?!][[Seems to work well]]

MD -> unsloth/gemma-4-26B-A4B-it-GGUF (kan dras via lemoande UI)

#### 32k contexct

--n-gpu-layers 999 --n-cpu-moe 15 --flash-attn on --cache-type-k q8_0 --cache-type-v q8_0 --batch-size 1024 --ubatch-size 512 --threads 8 --threads-batch 8 --parallel 1 --spec-type draft-mtp --spec-draft-n-max 4

#### 48k context (untested)

--n-gpu-layers 999 --n-cpu-moe 25 --flash-attn on --cache-type-k q8_0 --cache-type-v q8_0 --batch-size 1024 --ubatch-size 512 --threads 8 --threads-batch 8 --parallel 1 --spec-type draft-mtp --spec-draft-n-max 4

## ------------ QWEN --------------

### Qwen2.5-Coder-14B-Instruct-GGUF-Q4_K_M [[Works pretty poorly, tool calls sketchy]]

45 t/s+. Så snabb men ligger ju 100% i VRAM och q8 cache.

ARGS: --n-cpu-moe 0 --flash-attn on -ctk q8_0 -ctv q8_0

### Qwen3 Coder

lemonade pull unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Q4_K_M

ARGS Q8: --n-cpu-moe 18 -c 32768 -fa on -b 2048 -ub 2048 --cache-type-k q8_0 --cache-type-v q8_0 -t 8 --threads-batch 16

### Qwen3.6-35B-A3B-MTP-GGUF [REKOMMENDERAS?!][[Works very well, a bit slow but functional and descently smart]]

#### 32k context - moe 25

REN Q8 setup verkar snabbare, 25+ t/s (överlag Q8/Q4 verkar rätt dåligt)

ARGS: Q8: --n-cpu-moe 25 --flash-attn on -ctk q8_0 -ctv q8_0 -b 512 -ub 512 -t 8

#### 48k context (49152)

--n-cpu-moe 25 --flash-attn on -ctk q8_0 -ctv q8_0 -b 1024 -ub 512 -t 8 --threads-batch 8 --parallel 1

### Qwen3-Coder-30B-A3B-Instruct-GGUF-UD-Q4_K_XL

#### 32k context (coder)

moe15 = 92% (så rätt högt)

--n-gpu-layers 999 --n-cpu-moe 15 --flash-attn on --cache-type-k q8_0 --cache-type-v q8_0 --batch-size 1024 --ubatch-size 512 --threads 8 --threads-batch 8 --parallel 1

#### 49K Context (MINST 19 i moe..)

--n-gpu-layers 999 --n-cpu-moe 19 --flash-attn on --cache-type-k q8_0 --cache-type-v q8_0 --batch-size 1024 --ubatch-size 512 --threads 8 --threads-batch 8 --parallel 1

### Qwen3.8-27B-GGUF-UD-IQ3_XXS (unsloth)

96% CPU, PRECIS att det får plats.. 30+ t/s typ så snabb..

#### 32k context

--n-gpu-layers 999 --flash-attn on --cache-type-k q8_0 --cache-type-v q8_0 --batch-size 1024 --ubatch-size 512 --threads 8 --threads-batch 8 --parallel 1

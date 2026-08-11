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

## ------------- GEMMA4 --------------

## gemma-4-26B-A4B-it-GGUF-UD-Q4_K_M   [REKOMMENDERAS?!]

MD -> unsloth/gemma-4-26B-A4B-it-GGUF (kan dras via lemoande UI)

// EJ REK: ARGS Q8/Q4: --n-cpu-moe 10 -fa on -ctk q8_0 -ctv q4_0 -b 2048 -ub 2048 -t 8 -tb 16
ARGS Q8: --n-cpu-moe 14 -fa on -ctk q8_0 -ctv q8_0 -b 2048 -ub 2048 -t 8 -tb 16

### gemma-4-26B-A4B-it-GGUF-UD-IQ4_XS (13.8GB)

#### 32k context - Ingen moe offloading! Ser ut fungera med q4 cache v. 15-25 t/s vid chat essay riting = Ok(?)

lemonade load gemma-4-26B-A4B-it-GGUF-UD-IQ4_XS \
  --ctx-size 32768 \
  --llamacpp rocm \
  --llamacpp-args "--n-cpu-moe 0 -fa on -ctk q8_0 -ctv q4_0 -b 2048 -ub 2048 -t 8 -tb 16"

### gemma-4-26B-A4B-it-qat-GGUF-UD-Q4_K_XL (14.4GB)   [REKOMMENDERAS?!] 1,9t/s vid kod!!!!!!!!!!!!!!!

Samma resonemang, marginellt tightare pga större fil. K-quant (inte I-quant) brukar dessutom ha mognare ROCm-kärnor än IQ4_XS.

#### 32k context QAT. 8 moe offloading.  15-25 t/s vid chat essay riting = Ok(?)

lemonade load gemma-4-26B-A4B-it-qat-GGUF-UD-Q4_K_XL \
  --ctx-size 32768 \
  --llamacpp rocm \
  --llamacpp-args "--n-cpu-moe 7-fa on -ctk q8_0 -ctv q4_0 -b 2048 -ub 2048 -t 8 -tb 16"

## ------------ QWEN --------------

### Qwen2.5-Coder-14B-Instruct-GGUF-Q4_K_M

45 t/s+. Så snabb men ligger ju 100% i VRAM och q8 cache.

ARGS: --n-cpu-moe 0 --flash-attn on -ctk q8_0 -ctv q8_0

### Qwen3 Coder

lemonade pull unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Q4_K_M

ARGS Q8: --n-cpu-moe 18 -c 32768 -fa on -b 2048 -ub 2048 --cache-type-k q8_0 --cache-type-v q8_0 -t 8 --threads-batch 16

### Qwen3.6-35B-A3B-MTP-GGUF   [REKOMMENDERAS?!]

#### 32k context - moe 25

REN Q8 setup verkar snabbare, 25+ t/s (överlag Q8/Q4 verkar rätt dåligt)

ARGS: Q8: --n-cpu-moe 25 --flash-attn on -ctk q8_0 -ctv q8_0 -b 512 -ub 512 -t 8

### Qwen3.6-35B-A3B-MTP-GGUF-UD-IQ4_XS (17.8GB)

Omräknat mer exakt: filen är ~17.1GB experter fördelat på 40 lager (~0.43GB/lager). Med 16GB VRAM minus KV+overhead behöver du bara flytta ut ca 7-9 lager, inte 20+ som jag gissade förra gången.
  
#### 32k context - denna cfg ger 12t/s där runt när den skriver essays (osäker på kodning atm)

lemonade load Qwen3.6-35B-A3B-MTP-GGUF-UD-IQ4_XS \
  --ctx-size 32768 \
  --llamacpp rocm \
  --llamacpp-args "--n-cpu-moe 22 -fa on -ctk q8_0 -ctv q4_0 -b 2048 -ub 2048 -t 8 -tb 16"

// claude default: 8 moe, q8 cache

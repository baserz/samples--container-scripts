# Lemonade guides & howto

## Set quant in UI

--flash-attn --cache-type-k q8_0 --cache-type-v q8_0

## Models

## Qwen 3.6-35B-A3B-MTP-GGUF (Laddas ner via lemonade UI)

-> Bra, men rätt långsam <-

-ngl 22 --flash-attn on -ctk q8_0 -ctv q4_0 -b 512 -ub 512 -t 8

### Phi4

->Gör ej tool calling så rätt pointless<-

CMD -> lemonade pull unsloth/phi-4-GGUF:Q4_K_M (max 16384 token context)
ARGS -> --cache-type-k q8_0 --cache-type-v q8_0 --flash-attn on

### GPT OSS 20B

->Fungerar rätt dåligt intressant nog, gemma4 12b verkar bättre (!)<-

CMD -> lemonade pull gpt-oss-20b-q4_k_m
ARGS -> --cache-type-k q8_0 --cache-type-v q4_0 --flash-attn on

### Gemma 4 26B A4B

-><-

CMD -> unsloth/gemma-4-26B-A4B-it-GGUF (kan dras via lemoande UI)
ARGS -> --ngl 24 --flash-attn on -ctk q8_0 -ctv q4_0 -b 2048 -ub 512 -t 8
